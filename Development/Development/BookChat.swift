import ChatUI
import Foundation
import SwiftUI

// MARK: - Previews

private enum MessageSender {
  case me
  case other
}

private struct PreviewMessage: Identifiable {
  let id: UUID
  let text: String
  let sender: MessageSender

  init(id: UUID = UUID(), text: String, sender: MessageSender = .other) {
    self.id = id
    self.text = text
    self.sender = sender
  }
}

struct MessageListPreviewContainer: View {
  @State private var messages: [PreviewMessage] = [
    PreviewMessage(text: "Hello, how are you?", sender: .other),
    PreviewMessage(text: "I'm fine, thank you!", sender: .me),
    PreviewMessage(text: "What about you?", sender: .other),
    PreviewMessage(text: "I'm doing great, thanks for asking!", sender: .me),
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

//           Add older messages at the beginning
//           The scroll position will be automatically maintained
          let newMessages = (0..<5).map { index in
            olderMessageCounter -= 1
            let sender: MessageSender = index % 2 == 0 ? .me : .other
            return PreviewMessage(text: "Older message \(olderMessageCounter)", sender: sender)
          }
          messages.insert(contentsOf: newMessages.reversed(), at: 0)
        }
      ) { message in
        Text(message.text)
          .padding(12)
          .background(message.sender == .me ? Color.green.opacity(0.2) : Color.blue.opacity(0.1))
          .cornerRadius(8)
          .frame(maxWidth: .infinity, alignment: message.sender == .me ? .trailing : .leading)
      }

      HStack(spacing: 12) {
        Button("Add New Message") {
          newMessageCounter += 1
          let sender: MessageSender = Bool.random() ? .me : .other
          messages.append(PreviewMessage(text: "New message \(newMessageCounter)", sender: sender))
        }
        .buttonStyle(.borderedProminent)

        Button("Add Old Message") {
          olderMessageCounter -= 1
          let sender: MessageSender = Bool.random() ? .me : .other
          messages.insert(PreviewMessage(text: "Old message \(olderMessageCounter)", sender: sender), at: 0)
        }
        .buttonStyle(.bordered)

        Button("Clear All", role: .destructive) {
          messages.removeAll()
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
    PreviewMessage(text: "Hello, how are you?", sender: .other),
    PreviewMessage(text: "I'm fine, thank you!", sender: .me),
    PreviewMessage(text: "What about you?", sender: .other),
    PreviewMessage(text: "I'm doing great, thanks for asking!", sender: .me),
  ]) { message in
    Text(message.text)
      .padding(12)
      .background(message.sender == .me ? Color.green.opacity(0.2) : Color.blue.opacity(0.1))
      .cornerRadius(8)
      .frame(maxWidth: .infinity, alignment: message.sender == .me ? .trailing : .leading)
  }
  .padding()
}
