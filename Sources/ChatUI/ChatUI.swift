//
//  ChatUI.swift
//  swiftui-list-support
//
//  Created by Hiroshi Kimura on 2025/10/23.
//

import SwiftUI
import SwiftUIIntrospect
import Combine

#if canImport(UIKit)
import UIKit
#endif

/// # Spec
///
/// - `MessageList` renders every entry from `messages` as a padded, left-aligned bubble inside a vertical scroll view that keeps short lists anchored to the bottom.
/// - `MessageListPreviewContainer` provides sample data and hosts interactive controls for SwiftUI previews.
/// - Pressing `Add Message` appends a uniquely numbered placeholder to `messages`, allowing the preview to demonstrate dynamic updates.
/// - Supports loading older messages by scrolling up, with an optional loading indicator at the top.
public struct MessageList: View {

  public let messages: [String]
  private let isLoadingOlderMessages: Binding<Bool>?
  private let onLoadOlderMessages: (@MainActor () async -> Void)?

  public init(messages: [String]) {
    self.messages = messages
    self.isLoadingOlderMessages = nil
    self.onLoadOlderMessages = nil
  }

  public init(
    messages: [String],
    isLoadingOlderMessages: Binding<Bool>,
    onLoadOlderMessages: @escaping @MainActor () async -> Void
  ) {
    self.messages = messages
    self.isLoadingOlderMessages = isLoadingOlderMessages
    self.onLoadOlderMessages = onLoadOlderMessages
  }

  public var body: some View {
    ScrollView {
      LazyVStack(spacing: 8) {
        if let isLoadingOlderMessages {
          Section {
            ForEach(messages, id: \.self) { message in
              Text(message)
                .padding(12)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
          } header: {
            if isLoadingOlderMessages.wrappedValue {
              ProgressView()
                .frame(height: 40)
            }
          }
        } else {
          ForEach(messages, id: \.self) { message in
            Text(message)
              .padding(12)
              .background(Color.blue.opacity(0.1))
              .cornerRadius(8)
              .frame(maxWidth: .infinity, alignment: .leading)
          }
        }
      }
    }
    .defaultScrollAnchor(.bottom)
    .modifier(
      _OlderMessagesLoadingModifier(
        isLoadingOlderMessages: isLoadingOlderMessages,
        onLoadOlderMessages: onLoadOlderMessages
      )
    )
  }

}

// MARK: - Private Implementation

@MainActor
private final class _OlderMessagesLoadingController: ObservableObject {
  var scrollViewSubscription: AnyCancellable? = nil
  var currentLoadingTask: Task<Void, Never>? = nil

  // For scroll position preservation
  #if canImport(UIKit)
  weak var scrollViewRef: UIScrollView? = nil
  var contentOffsetObservation: NSKeyValueObservation? = nil
  var contentSizeObservation: NSKeyValueObservation? = nil
  var lastKnownContentOffset: CGFloat = 0
  var lastKnownContentHeight: CGFloat = 0
  #endif

  // For scroll direction detection
  var previousContentOffset: CGFloat? = nil

  nonisolated init() {}
}

private struct _OlderMessagesLoadingModifier: ViewModifier {
  @StateObject var controller: _OlderMessagesLoadingController = .init()

  private let isLoadingOlderMessages: Binding<Bool>?
  private let onLoadOlderMessages: (@MainActor () async -> Void)?
  private let leadingScreens: CGFloat = 1.0

  nonisolated init(
    isLoadingOlderMessages: Binding<Bool>?,
    onLoadOlderMessages: (@MainActor () async -> Void)?
  ) {
    self.isLoadingOlderMessages = isLoadingOlderMessages
    self.onLoadOlderMessages = onLoadOlderMessages
  }

  func body(content: Content) -> some View {
    if isLoadingOlderMessages != nil, onLoadOlderMessages != nil {
      if #available(iOS 18.0, macOS 15.0, *) {
        #if canImport(UIKit)
        content
          .introspect(.scrollView, on: .iOS(.v18, .v26)) { scrollView in
            // Save reference and setup monitoring
            setupScrollPositionPreservation(scrollView: scrollView)
          }
          .onScrollGeometryChange(for: _GeometryInfo.self) { geometry in
            return _GeometryInfo(
              contentOffset: geometry.contentOffset,
              contentSize: geometry.contentSize,
              containerSize: geometry.containerSize
            )
          } action: { _, geometry in
            let triggers = shouldTriggerLoading(
              contentOffset: geometry.contentOffset.y,
              boundsHeight: geometry.containerSize.height,
              contentHeight: geometry.contentSize.height
            )

            if triggers {
              Task { @MainActor in
                trigger()
              }
            }
          }
        #else
        content
        #endif
      } else {
        #if canImport(UIKit)
        content.introspect(.scrollView, on: .iOS(.v17)) { scrollView in
          // Save reference and setup monitoring
          setupScrollPositionPreservation(scrollView: scrollView)

          controller.scrollViewSubscription?.cancel()

          controller.scrollViewSubscription = scrollView.publisher(for: \.contentOffset)
            .sink { [weak scrollView] offset in
              guard let scrollView else { return }

              let triggers = shouldTriggerLoading(
                contentOffset: offset.y,
                boundsHeight: scrollView.bounds.height,
                contentHeight: scrollView.contentSize.height
              )

              if triggers {
                Task { @MainActor in
                  trigger()
                }
              }
            }
        }
        #else
        content
        #endif
      }
    } else {
      content
    }
  }

  private func shouldTriggerLoading(
    contentOffset: CGFloat,
    boundsHeight: CGFloat,
    contentHeight: CGFloat
  ) -> Bool {
    guard let isLoadingOlderMessages = isLoadingOlderMessages else { return false }
    guard !isLoadingOlderMessages.wrappedValue else { return false }
    guard controller.currentLoadingTask == nil else { return false }

    // Check scroll direction
    guard let previousOffset = controller.previousContentOffset else {
      // First time - can't determine direction, just save and skip
      controller.previousContentOffset = contentOffset
      return false
    }

    let isScrollingUp = contentOffset < previousOffset

    // Update previous offset for next comparison
    controller.previousContentOffset = contentOffset

    // Only trigger when scrolling up (towards older messages)
    guard isScrollingUp else {
      return false
    }

    let triggerDistance = boundsHeight * leadingScreens
    let distanceFromTop = contentOffset

    let shouldTrigger = distanceFromTop <= triggerDistance

    if shouldTrigger {
      print("[ChatUI] shouldTrigger: scrolling up, will trigger (offset: \(contentOffset), distance from top: \(distanceFromTop))")
    }

    return shouldTrigger
  }

  #if canImport(UIKit)
  @MainActor
  private func setupScrollPositionPreservation(scrollView: UIScrollView) {
    controller.scrollViewRef = scrollView

    // Clean up existing observations
    controller.contentOffsetObservation?.invalidate()
    controller.contentSizeObservation?.invalidate()

    // Monitor contentOffset to track current scroll position
    controller.contentOffsetObservation = scrollView.observe(\.contentOffset, options: [.new]) { [weak controller] scrollView, _ in
      MainActor.assumeIsolated {
        guard let controller = controller else { return }
        controller.lastKnownContentOffset = scrollView.contentOffset.y
      }
    }

    // Monitor contentSize to detect when content is added
    controller.contentSizeObservation = scrollView.observe(\.contentSize, options: [.old, .new]) { [weak controller] scrollView, change in
      MainActor.assumeIsolated {
        guard let controller = controller else { return }
        guard let oldHeight = change.oldValue?.height else { return }

        let newHeight = scrollView.contentSize.height
        let heightDiff = newHeight - oldHeight

        if heightDiff > 0 {
          // Content was added
          let savedOffset = controller.lastKnownContentOffset
          let newOffset = savedOffset + heightDiff

          print("[ChatUI] contentSize increased: oldHeight=\(oldHeight), newHeight=\(newHeight), heightDiff=\(heightDiff)")
          print("[ChatUI] adjusting offset from \(scrollView.contentOffset.y) to \(newOffset)")

          scrollView.contentOffset.y = newOffset

          print("[ChatUI] adjusted to \(scrollView.contentOffset.y)")
        }

        controller.lastKnownContentHeight = newHeight
      }
    }

    // Initialize with current values
    controller.lastKnownContentOffset = scrollView.contentOffset.y
    controller.lastKnownContentHeight = scrollView.contentSize.height
    print("[ChatUI] initialized: offset=\(scrollView.contentOffset.y), height=\(scrollView.contentSize.height)")
  }
  #endif

  @MainActor
  private func trigger() {
    guard let isLoadingOlderMessages = isLoadingOlderMessages else { return }
    guard let onLoadOlderMessages = onLoadOlderMessages else { return }
    guard !isLoadingOlderMessages.wrappedValue else { return }
    guard controller.currentLoadingTask == nil else { return }

    let task = Task { @MainActor in
      await withTaskCancellationHandler {
        isLoadingOlderMessages.wrappedValue = true
        print("[ChatUI] trigger: starting to load older messages")
        await onLoadOlderMessages()
        print("[ChatUI] trigger: finished loading older messages")
        isLoadingOlderMessages.wrappedValue = false

        controller.currentLoadingTask = nil
      } onCancel: {
        Task { @MainActor in
          isLoadingOlderMessages.wrappedValue = false
          controller.currentLoadingTask = nil
        }
      }

      // Debounce to avoid rapid re-triggering
      try? await Task.sleep(for: .seconds(0.1))
    }

    controller.currentLoadingTask = task
  }
}

// Helper struct for scroll geometry
private struct _GeometryInfo: Equatable {
  let contentOffset: CGPoint
  let contentSize: CGSize
  let containerSize: CGSize
}

// MARK: - Previews

private struct MessageListPreviewContainer: View {
  @State private var messages: [String] = [
    "Hello, how are you?",
    "I'm fine, thank you!",
    "What about you?",
    "I'm doing great, thanks for asking!",
  ]
  @State private var isLoadingOlder = false
  @State private var olderMessageCounter = 0

  var body: some View {
    VStack(spacing: 16) {
      Text("Scroll up to load older messages")
        .font(.caption)
        .foregroundStyle(.secondary)

      MessageList(
        messages: messages,
        isLoadingOlderMessages: $isLoadingOlder,
        onLoadOlderMessages: {
          print("Loading older messages...")
          try? await Task.sleep(for: .seconds(1))

          // Add older messages at the beginning
          // The scroll position will be automatically maintained
          let newMessages = (0..<5).map { index in
            olderMessageCounter -= 1
            return "Older message \(olderMessageCounter)"
          }
          messages.insert(contentsOf: newMessages.reversed(), at: 0)
        }
      )

      Button("Add Message") {
        let nextIndex = messages.count + 1
        messages.append("Additional message \(nextIndex)")
      }
      .buttonStyle(.borderedProminent)
      .frame(maxWidth: .infinity, alignment: .trailing)
    }
    .padding()
  }
}

#Preview("Interactive Preview") {
  MessageListPreviewContainer()
}

#Preview("Simple Preview") {
  MessageList(messages: [
    "Hello, how are you?",
    "I'm fine, thank you!",
    "What about you?",
    "I'm doing great, thanks for asking!",
  ])
  .padding()
}
