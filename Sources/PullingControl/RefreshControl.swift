import SwiftUI

public struct RefreshControlContext {

  public enum State {
    case idle
    case pulling(progress: Double)
    case refreshing
    case finishing
  }

  public let state: State
  public let pullDistance: CGFloat
  public let progress: Double

  init(
    state: State,
    pullDistance: CGFloat,
    progress: Double
  ) {
    self.state = state
    self.pullDistance = pullDistance
    self.progress = progress
  }
}

/// A customizable pull-to-refresh control for ScrollView.
/// Built on top of PullingControl with async action support and refreshing state management.
///
/// Example usage:
/// ```swift
/// ScrollView {
///   RefreshControl(action: {
///     await fetchData()
///   }) { context in
///     // Custom refresh indicator
///   }
///
///   // Your content
/// }
/// ```
public struct RefreshControl<Content: View>: View {

  private let threshold: CGFloat
  private let action: () async -> Void
  private let content: (RefreshControlContext) -> Content

  @State private var isRefreshing: Bool = false
  @State private var hasTriggered: Bool = false
  @State private var frozenPullDistance: CGFloat = 0

  public init(
    threshold: CGFloat = 80,
    action: @escaping () async -> Void,
    @ViewBuilder content: @escaping (RefreshControlContext) -> Content
  ) {
    self.threshold = threshold
    self.action = action
    self.content = content
  }

  public var body: some View {
    PullingControl(
      threshold: threshold,
      isExpanding: isRefreshing,
      onChange: { pullingContext in
        // Handle pulling state changes
        if !isRefreshing {
          if pullingContext.isThresholdReached && !hasTriggered {
            triggerRefresh()
          } else if !pullingContext.isPulling && hasTriggered {
            hasTriggered = false
          }
        }
      }
    ) { pullingContext in
      // Determine effective values based on refreshing state
      let effectivePullDistance = isRefreshing ? frozenPullDistance : pullingContext.pullDistance
      let effectiveProgress = isRefreshing ? (frozenPullDistance / threshold) : pullingContext.progress

      // Build RefreshControlContext from PullingContext
      let state: RefreshControlContext.State = {
        if isRefreshing {
          return .refreshing
        } else if pullingContext.isPulling {
          return .pulling(progress: effectiveProgress)
        } else {
          return .idle
        }
      }()

      let context = RefreshControlContext(
        state: state,
        pullDistance: effectivePullDistance,
        progress: effectiveProgress
      )

      return content(context)
    }
  }

  private func triggerRefresh() {
    hasTriggered = true
    frozenPullDistance = threshold
    isRefreshing = true

    // Haptic feedback
    #if os(iOS)
    let impact = UIImpactFeedbackGenerator(style: .medium)
    impact.prepare()
    impact.impactOccurred()
    #endif

    Task {
      // Perform the refresh action
      await action()

      // Reset state with animation
      withAnimation(.easeOut(duration: 0.3)) {
        isRefreshing = false
        hasTriggered = false
        frozenPullDistance = 0
      }
    }
  }
}



// MARK: - Previews

#Preview("Basic Refresh") {
  struct ContentView: View {
    @State private var items = Array(1...20)
    @State private var counter = 20

    var body: some View {
      ScrollView {
        VStack(spacing: 0) {
          RefreshControl(action: {
            // Simulate network delay
            try? await Task.sleep(nanoseconds: 2_000_000_000)

            // Add new items
            counter += 5
            items = Array(1...counter)
          }) { context in
            VStack(spacing: 8) {
              switch context.state {
              case .idle:
                EmptyView()
              case .pulling(let progress):
                Image(systemName: "arrow.down")
                  .font(.system(size: 16, weight: .medium))
                  .foregroundColor(.secondary)
                  .rotationEffect(.degrees(progress * 180))
                  .scaleEffect(0.8 + progress * 0.2)
                if progress > 0.5 {
                  Text(progress >= 1.0 ? "Release to refresh" : "Pull to refresh")
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
              case .refreshing:
                ProgressView()
                  .progressViewStyle(CircularProgressViewStyle())
                  .scaleEffect(0.9)
                Text("Refreshing...")
                  .font(.caption)
                  .foregroundColor(.secondary)
              case .finishing:
                Image(systemName: "checkmark.circle.fill")
                  .font(.system(size: 24))
                  .foregroundColor(.green)
              }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
          }

          LazyVStack(spacing: 12) {
            ForEach(items, id: \.self) { item in
              HStack {
                Text("Item \(item)")
                  .font(.headline)
                Spacer()
                Image(systemName: "chevron.right")
                  .font(.caption)
                  .foregroundColor(.secondary)
              }
              .padding()
              .background(Color.gray.opacity(0.1))
              .cornerRadius(10)
              .shadow(radius: 2)
            }
          }
          .padding()
        }
      }
      .background(Color.gray.opacity(0.05))
    }
  }

  return ContentView()
}

#Preview("Custom Indicator") {
  struct ContentView: View {
    @State private var lastRefresh = Date()

    var body: some View {
      ScrollView {
        VStack(spacing: 0) {
          RefreshControl(action: {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            lastRefresh = Date()
          }) { context in
            VStack(spacing: 4) {
              switch context.state {
              case .pulling:
                Circle()
                  .fill(Color.blue.opacity(context.progress))
                  .frame(width: 30, height: 30)
                  .overlay(
                    Text("\(Int(context.progress * 100))%")
                      .font(.caption2)
                      .foregroundColor(.white)
                  )
                  .scaleEffect(0.5 + context.progress * 0.5)

              case .refreshing:
                HStack(spacing: 4) {
                  ForEach(0..<3) { index in
                    Circle()
                      .fill(Color.blue)
                      .frame(width: 8, height: 8)
                      .scaleEffect(1.0)
                      .animation(
                        Animation.easeInOut(duration: 0.6)
                          .repeatForever()
                          .delay(Double(index) * 0.2),
                        value: context.pullDistance
                      )
                  }
                }
                .padding(.vertical, 11)

              default:
                EmptyView()
              }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
          }

          VStack(spacing: 16) {
            Text("Last refreshed:")
              .font(.headline)

            Text(lastRefresh, style: .relative)
              .font(.title2)
              .foregroundColor(.blue)

            ForEach(0..<10) { index in
              Text("Content Row \(index + 1)")
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
          }
          .padding()
        }
      }
    }
  }

  return ContentView()
}
