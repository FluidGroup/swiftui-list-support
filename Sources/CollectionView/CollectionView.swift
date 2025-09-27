import IndexedCollection
import SwiftUI

public struct CollectionView<
  Content: View,
  Layout: CollectionViewLayoutType
>: View {

  public let content: Content

  public let layout: Layout

  public init(
    layout: Layout,
    @ViewBuilder content: () -> Content
  ) {
    self.layout = layout
    self.content = content()
  }

  public var body: some View {
    Group {
      ModifiedContent(
        content: content,
        modifier: layout
      )
    }
  }

}

#if canImport(ScrollTracking)

@_spi(Internal)
import ScrollTracking

extension CollectionView {
   
  /// Attaches an infinite‑scroll style loader to a CollectionView that calls your async closure
  /// as the user approaches the end of the scrollable content.
  ///
  /// Use this modifier to automatically request and append more data to a `CollectionView` when the
  /// user scrolls near the end. The modifier observes the underlying scroll view produced by the
  /// selected layout and triggers `onLoad` once the remaining distance to the end is within
  /// `leadingScreens` times the visible length. If the content is initially smaller than the viewport,
  /// the loader triggers immediately so you can populate the view.
  ///
  /// The `isLoading` binding is managed for you: it is set to `true` just before `onLoad` runs and
  /// reset to `false` when it finishes. While `isLoading` is `true`, additional triggers are suppressed.
  /// Only one load task runs at a time, and subsequent triggers are slightly debounced to avoid rapid
  /// re‑invocation when the user hovers near the threshold.
  ///
  /// - Parameters:
  ///   - isEnabled: Toggles the behavior on or off. When `false`, no loading is triggered. Default is `true`.
  ///   - leadingScreens: The prefetch threshold expressed in multiples of the visible scrollable length
  ///     (height for vertical layouts). For example, `2` triggers when the user is within two screenfuls
  ///     of the end. Default is `2`.
  ///   - isLoading: A binding that reflects the current loading state. This modifier sets it to `true`
  ///     before calling `onLoad` and back to `false` when `onLoad` completes.
  ///   - onLoad: An async closure executed on the main actor when the threshold is crossed. Perform your
  ///     data fetch and append logic here.
  ///
  /// - Returns: A view that monitors scrolling and triggers `onLoad` according to the provided parameters.
  ///
  /// - Important: Avoid starting additional loads inside `onLoad` while `isLoading` is `true`. The
  ///   modifier already prevents re‑entrancy by tracking the current load task and debouncing subsequent
  ///   triggers.
  ///
  /// - Note:
  ///   - If the content length is smaller than the viewport, `onLoad` is triggered once on appear so
  ///     you can fetch enough items to fill the screen.
  ///   - Use non‑negative values for `leadingScreens`. Values near `0` trigger close to the end; larger
  ///     values prefetch earlier.
  ///
  /// - SeeAlso:
  ///   - ``onAdditionalLoading(isEnabled:leadingScreens:isLoading:onLoad:)`` (non‑binding overload)
  ///   - ``ScrollView/onAdditionalLoading(isEnabled:leadingScreens:isLoading:onLoad:)``
  ///   - ``List/onAdditionalLoading(isEnabled:leadingScreens:isLoading:onLoad:)``
  ///
  /// - Platform:
  ///   - On iOS 18, macOS 15, tvOS 18, watchOS 11, and visionOS 2 or later, the modifier uses SwiftUI
  ///     scroll geometry to observe position.
  ///   - On earlier supported iOS versions, it relies on scroll view introspection to observe content offset.
  ///
  /// - Example:
  ///   ```swift
  ///   struct FeedView: View {
  ///     @State private var items: [Item] = []
  ///     @State private var isLoading = false
  ///
  ///     var body: some View {
  ///       CollectionView(layout: .list) {
  ///         ForEach(items) { item in
  ///           Row(item: item)
  ///         }
  ///       }
  ///       .onAdditionalLoading(isEnabled: true,
  ///                            leadingScreens: 1.5,
  ///                            isLoading: $isLoading) {
  ///         // Fetch more and append
  ///         try? await Task.sleep(for: .seconds(1))
  ///         let more = await fetchMoreItems()
  ///         items.append(contentsOf: more)
  ///       }
  ///     }
  ///   }
  ///   ```
  @ViewBuilder
  public func onAdditionalLoading(
    isEnabled: Bool = true,
    leadingScreens: Double = 2,
    isLoading: Binding<Bool>,
    onLoad: @MainActor @escaping () async -> Void
  ) -> some View {
    
    self.onAdditionalLoading( 
      additionalLoading: .init(
        isEnabled: isEnabled,
        leadingScreens: leadingScreens,
        isLoading: isLoading,
        onLoad: onLoad
      )
    )
    
  }
  
  /// Triggers a load-more action as the user approaches the end of the scrollable content,
  /// without managing any loading state internally.
  /// 
  /// This modifier observes the scroll position of the collection and invokes `onLoad` when
  /// the visible region nears the end of the content by the amount specified in `leadingScreens`.
  /// It is conditionally available when the ScrollTracking module can be imported.
  /// 
  /// Use this overload when you already manage loading state externally (e.g., in a view model)
  /// and simply want a callback to fire when additional content should be fetched. If you want
  /// the modifier to help manage loading state and support async work, consider the binding-based,
  /// async overload instead.
  /// 
  /// - Parameters:
  ///   - isEnabled: A Boolean that enables or disables additional loading. When `false`, no callbacks
  ///     are fired. Defaults to `true`.
  ///   - leadingScreens: The prefetch distance, expressed as a multiple of the current viewport height.
  ///     For example, `2` means `onLoad` is triggered once the user scrolls within two screen-heights
  ///     of the end of the content. Defaults to `2`.
  ///   - isLoading: A Boolean that indicates whether a load is currently in progress. When `true`,
  ///     additional triggers are suppressed. This value is read-only from the modifier’s perspective;
  ///     you are responsible for updating it in your own state to avoid duplicate loads.
  ///   - onLoad: A closure executed on the main actor when the threshold is crossed and `isLoading` is `false`.
  ///     Use this to kick off your loading logic (e.g., dispatch an async task or call into a view model).
  /// 
  /// - Returns: A view that monitors scroll position and invokes `onLoad` as the user approaches the end.
  /// 
  /// - Discussion:
  ///   - The callback will not be invoked if the content is not scrollable, if `isEnabled` is `false`,
  ///     or while `isLoading` is `true`.
  ///   - Because this overload does not mutate `isLoading`, your code must set and clear loading state
  ///     to prevent repeated triggers.
  ///   - Choose `leadingScreens` based on your data-fetch latency and UI needs; values between `0.5` and `3`
  ///     are common depending on how early you want to prefetch.
  ///   - The `onLoad` closure runs on the main actor; if you need to perform asynchronous work,
  ///     start a `Task { ... }` inside the closure or delegate to your view model.
  /// 
  /// - SeeAlso: The binding-based async overload:
  ///   `onAdditionalLoading(isEnabled:leadingScreens:isLoading:onLoad:)` where `isLoading` is a `Binding<Bool>`
  ///   and `onLoad` is `async`, which can simplify state management for loading.
  /// 
  /// - Example:
  ///   ```swift
  ///   struct FeedView: View {
  ///     @StateObject private var viewModel = FeedViewModel()
  /// 
  ///     var body: some View {
  ///       CollectionView(layout: viewModel.layout) {
  ///         ForEach(viewModel.items) { item in
  ///           FeedRow(item: item)
  ///         }
  ///       }
  ///       .onAdditionalLoading(
  ///         isEnabled: true,
  ///         leadingScreens: 1.5,
  ///         isLoading: viewModel.isLoading
  ///       ) {
  ///         // Executed on the main actor
  ///         viewModel.loadMore()
  ///       }
  ///     }
  ///   }
  ///   ```
  @ViewBuilder
  public func onAdditionalLoading(
    isEnabled: Bool = true,
    leadingScreens: Double = 2,
    isLoading: Bool,
    onLoad: @escaping @MainActor () -> Void
  ) -> some View {
    self.onAdditionalLoading( 
      additionalLoading: .init(
        isEnabled: isEnabled,
        leadingScreens: leadingScreens,
        isLoading: isLoading,
        onLoad: onLoad
      )
    )
  }
  
}

#endif
