import SwiftUI

/// Context provided to the content builder of PullingControl
public struct PullingContext: Equatable {
  /// The current pull distance in points
  public let pullDistance: CGFloat

  /// Progress from 0.0 to 1.0 based on threshold
  public let progress: Double

  /// Whether the pull distance has reached the threshold
  public let isThresholdReached: Bool

  /// Whether the view is currently being pulled (pullDistance > 0)
  public let isPulling: Bool

  init(
    pullDistance: CGFloat,
    progress: Double,
    isThresholdReached: Bool,
    isPulling: Bool
  ) {
    self.pullDistance = pullDistance
    self.progress = progress
    self.isThresholdReached = isThresholdReached
    self.isPulling = isPulling
  }
}

/// A low-level control that detects pull gestures in a ScrollView.
/// This provides the foundation for pull-to-refresh and similar interactions.
///
/// Example usage:
/// ```swift
/// ScrollView {
///   PullingControl(
///     threshold: 80,
///     isExpanding: isLoading,  // Keep height at threshold when true
///     onChange: { context in
///       if context.isThresholdReached {
///         // Handle threshold reached while pulling
///       }
///     }
///   ) { context in
///     if context.isThresholdReached {
///       Text("Release to trigger!")
///     } else if context.isPulling {
///       Text("Pull progress: \(Int(context.progress * 100))%")
///     }
///   }
///
///   // Your content
/// }
/// ```
public struct PullingControl<Content: View>: View {

  private let threshold: CGFloat
  private let isExpanding: Bool
  private let onChange: ((PullingContext) -> Void)?
  private let content: (PullingContext) -> Content

  @State private var pullDistance: CGFloat = 0

  public init(
    threshold: CGFloat = 80,
    isExpanding: Bool = false,
    onChange: ((PullingContext) -> Void)? = nil,
    @ViewBuilder content: @escaping (PullingContext) -> Content
  ) {
    self.threshold = threshold
    self.isExpanding = isExpanding
    self.onChange = onChange
    self.content = content
  }

  private func makeContext(pullDistance: CGFloat) -> PullingContext {
    let progress = min(1.0, max(0.0, pullDistance / threshold))
    let isThresholdReached = pullDistance >= threshold
    let isPulling = pullDistance > 0

    return PullingContext(
      pullDistance: pullDistance,
      progress: progress,
      isThresholdReached: isThresholdReached,
      isPulling: isPulling
    )
  }

  public var body: some View {
    let context = makeContext(pullDistance: pullDistance)
    let effectiveHeight = isExpanding ? threshold : pullDistance

    content(context)
      .frame(height: max(0.5, effectiveHeight))
      .onGeometryChange(
        for: CGFloat.self,
        of: { geometry in
          geometry.frame(in: .scrollView).minY
        }
      ) { minY in
        // Only track positive overscroll
        pullDistance = max(0, minY)
      }
      .onChange(of: context) { _, newContext in
        onChange?(newContext)
      }
  }
}

// MARK: - Previews

#Preview("Simple Text Indicator") {
  struct ContentView: View {

    var body: some View {

      ScrollView {
        VStack(spacing: 0) {
          PullingControl(threshold: 80) { context in
            VStack(spacing: 4) {
              if context.isPulling {
                Text(
                  context.isThresholdReached
                    ? "Threshold Reached!" : "Pulling..."
                )
                .font(.caption)
                .foregroundColor(
                  context.isThresholdReached ? .green : .secondary
                )

                Text("Progress: \(Int(context.progress * 100))%")
                  .font(.caption2)
                  .foregroundColor(.gray)
              }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
          }

          LazyVStack(spacing: 12) {
            ForEach(0..<20, id: \.self) { item in
              Text("Item \(item + 1)")
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

#Preview("Debug Info") {
  struct ContentView: View {
    var body: some View {
      ScrollView {
        VStack(spacing: 0) {
          PullingControl(threshold: 100) { context in
            if context.isPulling {
              VStack(alignment: .leading, spacing: 2) {
                Text(
                  "pullDistance: \(String(format: "%.1f", context.pullDistance))"
                )
                Text("progress: \(String(format: "%.2f", context.progress))")
                Text(
                  "isThresholdReached: \(context.isThresholdReached ? "true" : "false")"
                )
              }
              .font(.caption)
              .foregroundColor(.secondary)
              .frame(maxWidth: .infinity)
              .padding(.vertical, 8)
            }
          }

          VStack(spacing: 16) {
            ForEach(0..<15) { index in
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

#Preview("With onChange Callback") {
  struct ContentView: View {
    var body: some View {
      ScrollView {
        VStack(spacing: 0) {
          PullingControl(
            threshold: 80,
            onChange: { context in
              print(
                "[onChange] pullDistance: \(String(format: "%.1f", context.pullDistance)), progress: \(String(format: "%.2f", context.progress)), isThresholdReached: \(context.isThresholdReached)"
              )
            }
          ) { context in
            VStack(spacing: 4) {
              if context.isPulling {
                Text(
                  context.isThresholdReached
                    ? "Threshold Reached!" : "Pulling..."
                )
                .font(.caption)
                .foregroundColor(
                  context.isThresholdReached ? .green : .secondary
                )

                Text("Progress: \(Int(context.progress * 100))%")
                  .font(.caption2)
                  .foregroundColor(.gray)
              }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
          }

          VStack(spacing: 8) {
            Text("Check Console for Logs")
              .font(.headline)
              .foregroundColor(.secondary)
              .frame(maxWidth: .infinity)
              .padding()
              .background(Color.yellow.opacity(0.1))
              .cornerRadius(8)
          }
          .padding()

          LazyVStack(spacing: 12) {
            ForEach(0..<20, id: \.self) { item in
              Text("Item \(item + 1)")
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
