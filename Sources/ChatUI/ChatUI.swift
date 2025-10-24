//
//  ChatUI.swift
//  swiftui-list-support
//
//  Created by Hiroshi Kimura on 2025/10/23.
//

import SwiftUI
import SwiftUIIntrospect
import Combine

/// # Spec
///
/// - `MessageList` renders every entry from `messages` as a padded, left-aligned bubble inside a vertical scroll view that keeps short lists anchored to the bottom.
/// - `MessageListPreviewContainer` provides sample data and hosts interactive controls for SwiftUI previews.
/// - Pressing `Add Message` appends a uniquely numbered placeholder to `messages`, allowing the preview to demonstrate dynamic updates.
/// - Supports loading older messages by scrolling up, with an optional loading indicator at the top.
public struct MessageList: View {

  public let messages: [String]
  private let isLoadingOlderMessages: Binding<Bool>?
  private let autoScrollToBottom: Binding<Bool>?
  private let onLoadOlderMessages: (@MainActor () async -> Void)?

  public init(messages: [String]) {
    self.messages = messages
    self.isLoadingOlderMessages = nil
    self.autoScrollToBottom = nil
    self.onLoadOlderMessages = nil
  }

  public init(
    messages: [String],
    isLoadingOlderMessages: Binding<Bool>,
    autoScrollToBottom: Binding<Bool>? = nil,
    onLoadOlderMessages: @escaping @MainActor () async -> Void
  ) {
    self.messages = messages
    self.isLoadingOlderMessages = isLoadingOlderMessages
    self.autoScrollToBottom = autoScrollToBottom
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
        autoScrollToBottom: autoScrollToBottom,
        onLoadOlderMessages: onLoadOlderMessages
      )
    )
  }

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
  @State private var autoScrollToBottom = true
  @State private var olderMessageCounter = 0
  @State private var newMessageCounter = 0

  var body: some View {
    VStack(spacing: 16) {
      VStack(spacing: 8) {
        Toggle("Auto-scroll to new messages", isOn: $autoScrollToBottom)
          .font(.caption)

        Text("Scroll up to load older messages")
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      MessageList(
        messages: messages,
        isLoadingOlderMessages: $isLoadingOlder,
        autoScrollToBottom: $autoScrollToBottom,
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

      HStack(spacing: 12) {
        Button("Add New Message") {
          newMessageCounter += 1
          messages.append("New message \(newMessageCounter)")
        }
        .buttonStyle(.borderedProminent)

        Button("Add Old Message (Bottom)") {
          let nextIndex = messages.count + 1
          messages.append("Additional message \(nextIndex)")
        }
        .buttonStyle(.bordered)
      }
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
