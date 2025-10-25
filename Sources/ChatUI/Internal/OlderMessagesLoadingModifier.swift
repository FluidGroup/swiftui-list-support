//
//  OlderMessagesLoadingModifier.swift
//  swiftui-list-support
//
//  Created by Hiroshi Kimura on 2025/10/23.
//

import SwiftUI
import SwiftUIIntrospect
import UIKit

struct _OlderMessagesLoadingModifier: ViewModifier {
  @StateObject var controller: _OlderMessagesLoadingController = .init()

  private let isLoadingOlderMessages: Binding<Bool>?
  private let autoScrollToBottom: Binding<Bool>?
  private let onLoadOlderMessages: (@MainActor () async -> Void)?
  private let leadingScreens: CGFloat = 1.0

  nonisolated init(
    isLoadingOlderMessages: Binding<Bool>?,
    autoScrollToBottom: Binding<Bool>?,
    onLoadOlderMessages: (@MainActor () async -> Void)?
  ) {
    self.isLoadingOlderMessages = isLoadingOlderMessages
    self.autoScrollToBottom = autoScrollToBottom
    self.onLoadOlderMessages = onLoadOlderMessages
  }

  func body(content: Content) -> some View {
    if isLoadingOlderMessages != nil, onLoadOlderMessages != nil {
      if #available(iOS 18.0, macOS 15.0, *) {
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
      } else {
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

  @MainActor
  private func setupScrollPositionPreservation(scrollView: UIScrollView) {
    controller.scrollViewRef = scrollView

    // Clean up existing observations
    controller.contentSizeObservation?.invalidate()

    // Monitor contentSize to detect when content is added
    controller.contentSizeObservation = scrollView.observe(\.contentSize, options: [.old, .new]) {
      [weak controller] scrollView, change in
      MainActor.assumeIsolated {
        guard let controller = controller else { return }
        guard let oldHeight = change.oldValue?.height else { return }

        let newHeight = scrollView.contentSize.height
        let heightDiff = newHeight - oldHeight

        // Content size increased
        if heightDiff > 0 {
          let currentOffset = scrollView.contentOffset.y
          let boundsHeight = scrollView.bounds.height

          // Case 1: autoScrollToBottom enabled → scroll to bottom
          if let autoScrollToBottom = autoScrollToBottom,
             autoScrollToBottom.wrappedValue {
            let bottomOffset = newHeight - boundsHeight
            UIView.animate(withDuration: 0.3) {
              scrollView.contentOffset.y = max(0, bottomOffset)
            }
          }
          // Case 2: User is viewing history → preserve scroll position
          else {
            let newOffset = currentOffset + heightDiff
            scrollView.contentOffset.y = newOffset
          }
        }

        controller.lastKnownContentHeight = newHeight
        controller.lastKnownContentOffset = scrollView.contentOffset.y
      }
    }

    // Initialize with current values
    controller.lastKnownContentHeight = scrollView.contentSize.height
    controller.lastKnownContentOffset = scrollView.contentOffset.y
  }

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
struct _GeometryInfo: Equatable {
  let contentOffset: CGPoint
  let contentSize: CGSize
  let containerSize: CGSize
}
