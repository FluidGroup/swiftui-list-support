//
//  ChatUI.swift
//  swiftui-list-support
//
//  Created by Hiroshi Kimura on 2025/10/23.
//

import SwiftUI

/// # Spec
///
/// - `MessageList` renders every entry from `messages` as a padded, left-aligned bubble inside a vertical scroll view that keeps short lists anchored to the bottom.
/// - `MessageListPreviewContainer` provides sample data and hosts interactive controls for SwiftUI previews.
/// - Pressing `Add Message` appends a uniquely numbered placeholder to `messages`, allowing the preview to demonstrate dynamic updates.
public struct MessageList: View {

  public let messages: [String]

  public init(messages: [String]) {
    self.messages = messages
  }

  public var body: some View {
    ScrollView {
      LazyVStack(spacing: 8) {
        ForEach(messages, id: \.self) { message in
          Text(message)
            .padding(12)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
      }
    }
    .defaultScrollAnchor(.bottom)
  }

}

private struct MessageListPreviewContainer: View {
  @State private var messages: [String] = [
    "Hello, how are you?",
    "I'm fine, thank you!",
    "What about you?",
    "I'm doing great, thanks for asking!",
  ]

  var body: some View {
    VStack(spacing: 16) {
      MessageList(messages: messages)
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
