//
//  OlderMessagesLoadingController.swift
//  swiftui-list-support
//
//  Created by Hiroshi Kimura on 2025/10/23.
//

import SwiftUI
import Combine
import UIKit

@MainActor
final class _OlderMessagesLoadingController: ObservableObject {
  var scrollViewSubscription: AnyCancellable? = nil
  var currentLoadingTask: Task<Void, Never>? = nil

  // For scroll position preservation
  weak var scrollViewRef: UIScrollView? = nil
  var contentOffsetObservation: NSKeyValueObservation? = nil
  var contentSizeObservation: NSKeyValueObservation? = nil
  var lastKnownContentOffset: CGFloat = 0
  var lastKnownContentHeight: CGFloat = 0

  // For scroll direction detection
  var previousContentOffset: CGFloat? = nil

  // For auto-scroll to bottom
  var autoScrollToBottom: Bool = false

  nonisolated init() {}
}
