import Combine
import SwiftUI
import SwiftUIIntrospect
import os.lock

extension View {

  @_spi(Internal)
  public func onAdditionalLoading(
    additionalLoading: AdditionalLoading
  ) -> some View {

    modifier(
      _Modifier(
        additionalLoading: additionalLoading
      )
    )

  }
}

extension ScrollView {

  /// Attaches an infinite-scrolling style loader that calls your async closure
  /// as the user approaches the end of the scrollable content.
  ///
  /// Use this modifier to automatically request and append more data to a
  /// `ScrollView` when the user scrolls near the bottom. The modifier observes
  /// the scroll position and triggers `onLoad` once the remaining distance to
  /// the end is within `leadingScreens` times the visible height. If the content
  /// is initially smaller than the viewport, the loader triggers immediately.
  ///
  /// The `isLoading` binding is managed for you: it is set to `true` just before
  /// `onLoad` runs and reset to `false` when it finishes. While `isLoading` is
  /// `true`, additional triggers are suppressed. Only one load task runs at a
  /// time, and subsequent triggers are slightly debounced to avoid rapid
  /// re-invocation when the user hovers near the threshold.
  ///
  /// - Parameters:
  ///   - isEnabled: Toggles the behavior on or off. When `false`, no loading is
  ///     triggered. Default is `true`.
  ///   - leadingScreens: The prefetch threshold expressed in multiples of the
  ///     visible scrollable height. For example, `2` triggers when the user is
  ///     within two screenfuls of the bottom. Default is `2`.
  ///   - isLoading: A binding that reflects the current loading state. This
  ///     modifier sets it to `true` before calling `onLoad` and back to `false`
  ///     when `onLoad` completes.
  ///   - onLoad: An async closure executed on the main actor when the threshold
  ///     is crossed. Perform your data fetch and append logic here.
  ///
  /// - Returns: A view that monitors scrolling and triggers `onLoad` according to
  ///   the provided parameters.
  ///
  /// - Important: Avoid starting additional loads inside `onLoad` while
  ///   `isLoading` is `true`. The modifier already prevents re-entrancy by
  ///   tracking the current load task and debouncing subsequent triggers.
  ///
  /// - Note:
  ///   - If the content height is smaller than the viewport, `onLoad` is
  ///     triggered once on appear so you can fetch enough items to fill the
  ///     screen.
  ///   - Use non-negative values for `leadingScreens`. Values near `0` trigger
  ///     close to the bottom; larger values prefetch earlier.
  ///
  /// - SeeAlso:
  ///   - ``onAdditionalLoading(isEnabled:leadingScreens:isLoading:onLoad:)`` on ``List``
  ///   - ``onAdditionalLoading(isEnabled:leadingScreens:isLoading:onLoad:)`` (non-binding overload)
  ///
  /// - Platform:
  ///   - On iOS 18, macOS 15, tvOS 18, watchOS 11, and visionOS 2 or later,
  ///     the modifier uses SwiftUI scroll geometry to observe position.
  ///   - On earlier supported iOS versions, it relies on scroll view introspection
  ///     to observe content offset.
  @ViewBuilder
  public func onAdditionalLoading(
    isEnabled: Bool = true,
    leadingScreens: Double = 2,
    isLoading: Binding<Bool>,
    onLoad: @escaping @MainActor () async -> Void
  ) -> some View {

    modifier(
      _Modifier(
        additionalLoading: .init(
          isEnabled: isEnabled,
          leadingScreens: leadingScreens,
          isLoading: isLoading,
          onLoad: onLoad
        )
      )
    )

  }

  /// Adds "infinite scrolling" behavior to a ScrollView by invoking a closure when the user approaches
  /// the end of the scrollable content.
  ///
  /// This overload is designed for callers who manage their own loading state and perform a synchronous
  /// action on the main actor. If you prefer the modifier to drive the loading state for you and to
  /// support asynchronous loading, use the variant that takes a `Binding<Bool>` and an `async` closure.
  ///
  /// Behavior
  /// - When the remaining distance to the bottom of the content becomes less than or equal to
  ///   `leadingScreens * viewportHeight`, `onLoad` is called.
  /// - If the content is smaller than the viewport, `onLoad` is also called (to allow initial prefetch).
  /// - Triggers are suppressed while `isEnabled` is `false`, while `isLoading` is `true`, and while a
  ///   previous load triggered by this modifier is still in progress. A brief delay is applied after
  ///   completion to avoid rapid duplicate triggers.
  /// - `onLoad` is executed on the main actor. Move heavy work off the main actor or use the async/Binding
  ///   overload if you need structured concurrency.
  ///
  /// Platform availability
  /// - iOS 15.0+
  /// - macOS 15.0+
  /// - tvOS 18.0+
  /// - watchOS 11.0+
  /// - visionOS 2.0+
  ///
  /// Parameters
  /// - isEnabled: Toggles additional-loading behavior on or off. Defaults to `true`.
  /// - leadingScreens: The prefetch threshold expressed in multiples of the current viewport height.
  ///   For example, a value of `2` triggers when the user is within two screen-heights of the bottom.
  ///   Use `0` to trigger only when reaching the very end. Prefer non-negative values.
  ///   Defaults to `2`.
  /// - isLoading: Your current loading state. While this is `true`, no new loads will be triggered.
  ///   Note: This overload does not mutate your loading state; you must update it yourself in
  ///   response to `onLoad`. If you want automatic state management, use the overload that takes
  ///   a `Binding<Bool>`.
  /// - onLoad: A closure executed on the main actor when prefetch should occur. This closure is
  ///   synchronous; if you need to perform asynchronous work, start a `Task` inside the closure
  ///   or use the async/Binding overload.
  ///
  /// Returns
  /// - A view that triggers `onLoad` when the user scrolls near the end of the content.
  ///
  /// See also
  /// - `onAdditionalLoading(isEnabled:leadingScreens:isLoading:onLoad:)` where `isLoading` is a
  ///   `Binding<Bool>` and `onLoad` is `async`, which automatically toggles the loading state for you.
  ///
  /// Example
  /// ```swift
  /// struct FeedView: View {
  ///   @State private var items: [Item] = []
  ///   @State private var isLoading = false
  ///
  ///   var body: some View {
  ///     ScrollView {
  ///       LazyVStack {
  ///         ForEach(items) { item in
  ///           Row(item: item)
  ///         }
  ///       }
  ///     }
  ///     .onAdditionalLoading(
  ///       isEnabled: true,
  ///       leadingScreens: 1,
  ///       isLoading: isLoading  // pass the current value
  ///     ) {
  ///       // This closure runs on the main actor and is synchronous.
  ///       // Manage your own loading state and async work:
  ///       guard !isLoading else { return }
  ///       isLoading = true
  ///       Task {
  ///         defer { await MainActor.run { isLoading = false } }
  ///         let more = await fetchMoreItems()
  ///         await MainActor.run { items.append(contentsOf: more) }
  ///       }
  ///     }
  ///   }
  /// }
  /// ```
  @ViewBuilder
  public func onAdditionalLoading(
    isEnabled: Bool = true,
    leadingScreens: Double = 2,
    isLoading: Bool,
    onLoad: @escaping @MainActor () -> Void
  ) -> some View {

    modifier(
      _Modifier(
        additionalLoading: .init(
          isEnabled: isEnabled,
          leadingScreens: leadingScreens,
          isLoading: isLoading,
          onLoad: onLoad
        )
      )
    )

  }

}

extension List {
  @ViewBuilder
  public func onAdditionalLoading(
    isEnabled: Bool = true,
    leadingScreens: Double = 2,
    isLoading: Binding<Bool>,
    onLoad: @escaping @MainActor () async -> Void
  ) -> some View {

    modifier(
      _Modifier(
        additionalLoading: .init(
          isEnabled: isEnabled,
          leadingScreens: leadingScreens,
          isLoading: isLoading,
          onLoad: onLoad
        )
      )
    )
  }
}

public struct AdditionalLoading: Sendable {

  public let isEnabled: Bool
  public let leadingScreens: Double
  public let isLoading: Bool
  public let onLoad: @MainActor () async -> Void

  public init(
    isEnabled: Bool,
    leadingScreens: Double,
    isLoading: Binding<Bool>,
    onLoad: @escaping @MainActor () async -> Void
  ) {
    self.isEnabled = isEnabled
    self.leadingScreens = leadingScreens
    self.isLoading = isLoading.wrappedValue
    self.onLoad = {
      isLoading.wrappedValue = true
      await onLoad()
      isLoading.wrappedValue = false
    }
  }

  public init(
    isEnabled: Bool,
    leadingScreens: Double,
    isLoading: Bool,
    onLoad: @escaping @MainActor () -> Void
  ) {
    self.isEnabled = isEnabled
    self.leadingScreens = leadingScreens
    self.isLoading = isLoading
    self.onLoad = onLoad
  }

}

@MainActor
private final class Controller: ObservableObject {

  var scrollViewSubscription: AnyCancellable? = nil
  var currentLoadingTask: Task<Void, Never>? = nil

  nonisolated init() {}
}

@available(iOS 15.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
private struct _Modifier: ViewModifier {

  @StateObject var controller: Controller = .init()

  private let additionalLoading: AdditionalLoading

  nonisolated init(
    additionalLoading: AdditionalLoading
  ) {
    self.additionalLoading = additionalLoading
  }

  func body(content: Content) -> some View {

    if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0,
    *) {
      content.onScrollGeometryChange(for: ScrollGeometry.self) { geometry in

        return geometry

      } action: { _, geometry in
        let triggers = calculate(
          contentOffsetY: geometry.contentOffset.y,
          boundsHeight: geometry.containerSize.height,
          contentSizeHeight: geometry.contentSize.height,
          leadingScreens: additionalLoading.leadingScreens
        )

        if triggers {
          Task { @MainActor in
            trigger()
          }
        }

      }
    } else {

      #if canImport(UIKit)

        content.introspect(.scrollView, on: .iOS(.v15, .v16, .v17)) {
          scrollView in

          controller.scrollViewSubscription?.cancel()

          controller.scrollViewSubscription = scrollView.publisher(
            for: \.contentOffset
          ).sink {
            [weak scrollView] offset in

            guard let scrollView else {
              return
            }

            let triggers = calculate(
              contentOffsetY: offset.y,
              boundsHeight: scrollView.bounds.height,
              contentSizeHeight: scrollView.contentSize.height,
              leadingScreens: additionalLoading.leadingScreens
            )

            if triggers {
              Task { @MainActor in
                trigger()
              }
            }

          }
        }
      #else
        fatalError()
      #endif
    }
  }

  @MainActor
  private func trigger() {

    guard additionalLoading.isEnabled else {
      return
    }

    guard additionalLoading.isLoading == false else {
      return
    }

    guard controller.currentLoadingTask == nil else {
      return
    }

    let task = Task { @MainActor in
      await withTaskCancellationHandler {
        await additionalLoading.onLoad()
        controller.currentLoadingTask = nil
      } onCancel: {
        Task { @MainActor in
          controller.currentLoadingTask = nil
        }
      }

      // easiest way to avoid multiple triggers
      try? await Task.sleep(for: .seconds(0.1))
    }

    controller.currentLoadingTask = task

  }

}

private func calculate(
  contentOffsetY: CGFloat,
  boundsHeight: CGFloat,
  contentSizeHeight: CGFloat,
  leadingScreens: CGFloat
) -> Bool {

  guard leadingScreens > 0 || boundsHeight != .zero else {
    return false
  }

  let viewLength = boundsHeight
  let offset = contentOffsetY
  let contentLength = contentSizeHeight

  let hasSmallContent = (offset == 0.0) && (contentLength < viewLength)

  let triggerDistance = viewLength * leadingScreens
  let remainingDistance = contentLength - viewLength - offset

  return (hasSmallContent || remainingDistance <= triggerDistance)
}

@available(iOS 17, *)
#Preview {
  @Previewable @State var items = Array(0..<20)
  @Previewable @State var isLoading = false

  List(items, id: \.self) { index in
    Text("Item \(index)")
      .frame(height: 50)
      .background(Color.red)
  }
  .onAdditionalLoading(
    isLoading: $isLoading,
    onLoad: {
      try? await Task.sleep(for: .seconds(1))
      let lastItem = items.last ?? -1
      let newItems = Array((lastItem + 1)..<(lastItem + 21))
      items.append(contentsOf: newItems)
    }
  )
  .onAppear {
    print("Hello")
  }
}

@available(iOS 17, *)
#Preview("ScrollView") {
  @Previewable @State var items = Array(0..<20)
  @Previewable @State var isLoading = false

  ScrollView {
    LazyVStack {
      Section {
        ForEach(items, id: \.self) { index in
          Text("Item \(index)")
            .frame(height: 50)
            .background(Color.blue)
        }
      } footer: {
        if isLoading {
          ProgressView()
            .frame(height: 50)
        }
      }
    }
  }
  .onAdditionalLoading(
    isLoading: $isLoading,
    onLoad: {
      try? await Task.sleep(for: .seconds(1))
      let lastItem = items.last ?? -1
      let newItems = Array((lastItem + 1)..<(lastItem + 21))
      items.append(contentsOf: newItems)
    }
  )
  .onAppear {
    print("Hello")
  }
}

@available(iOS 17, *)
#Preview("ScrollView Non-Binding") {
  @Previewable @State var items = Array(0..<20)
  @Previewable @State var isLoading = false

  ScrollView {
    LazyVStack {

      Section {
        ForEach(items, id: \.self) { index in
          Text("Item \(index)")
            .frame(height: 50)
            .background(Color.blue)
        }
      } footer: {
        if isLoading {
          ProgressView()
            .frame(height: 50)
        }
      }

    }
  }
  .onAdditionalLoading(
    isLoading: isLoading,
    onLoad: {
      guard !isLoading else {
        print("Skip")
        return
      }
      isLoading = true
      print("Load triggered")
      Task {
        try? await Task.sleep(for: .seconds(1))
        let lastItem = items.last ?? -1
        let newItems = Array((lastItem + 1)..<(lastItem + 21))
        items.append(contentsOf: newItems)
        isLoading = false
      }
    }
  )
}
