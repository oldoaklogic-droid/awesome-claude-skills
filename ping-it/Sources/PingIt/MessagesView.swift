import SwiftUI

struct MessagesView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        List {
            ForEach(store.conversations) { conversation in
                NavigationLink(value: conversation.id) {
                    ConversationRow(conversation: conversation)
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Messages")
        .navigationDestination(for: UUID.self) { conversationID in
            ChatView(conversationID: conversationID)
        }
    }
}

private struct ConversationRow: View {
    @EnvironmentObject private var store: AppStore
    let conversation: Conversation

    var body: some View {
        let partner = store.user(conversation.participantID)
        let last = conversation.messages.last
        HStack(spacing: 12) {
            AvatarView(user: partner, size: 46)
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    UserNameLine(user: partner, showsHandle: false)
                    Spacer()
                    if let last {
                        Text(shortRelativeDate(last.date))
                            .font(.caption)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }
                Text(last?.text ?? "Start the conversation")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            if conversation.unreadCount > 0 {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 10, height: 10)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ChatView: View {
    @EnvironmentObject private var store: AppStore
    let conversationID: UUID
    @State private var draft = ""

    private var conversation: Conversation? {
        store.conversations.first { $0.id == conversationID }
    }

    var body: some View {
        if let conversation {
            let partner = store.user(conversation.participantID)
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(conversation.messages) { message in
                                MessageBubble(message: message,
                                              isMine: message.senderID == store.currentUserID)
                                    .id(message.id)
                                    .transition(.move(edge: .bottom).combined(with: .opacity))
                            }
                        }
                        .padding(12)
                        .animation(Motion.standard, value: conversation.messages.count)
                    }
                    .onChange(of: conversation.messages.count) {
                        if let lastID = conversation.messages.last?.id {
                            withAnimation(Motion.smooth) {
                                proxy.scrollTo(lastID, anchor: .bottom)
                            }
                        }
                    }
                    .onAppear {
                        store.markConversationRead(conversationID)
                        if let lastID = conversation.messages.last?.id {
                            proxy.scrollTo(lastID, anchor: .bottom)
                        }
                    }
                }

                Divider()
                HStack(spacing: 8) {
                    TextField("Start a new message", text: $draft, axis: .vertical)
                        .textFieldStyle(.plain)
                        .lineLimit(1...4)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(.quaternary.opacity(0.4))
                        )
                        .onSubmit(send)
                    Button {
                        send()
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .foregroundStyle(.white)
                            .frame(width: 34, height: 34)
                            .background(Circle().fill(Color.accentColor))
                    }
                    .buttonStyle(PressableStyle(scale: 0.9))
                    .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.4 : 1)
                    .animation(Motion.fade, value: draft.isEmpty)
                }
                .padding(12)
                .background(.ultraThinMaterial)
            }
            .navigationTitle(partner.displayName)
            .navigationBarTitleDisplayMode(.inline)
        } else {
            EmptyStateView(symbol: "envelope.open",
                           title: "No conversation",
                           message: "This conversation is no longer available.")
        }
    }

    private func send() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        store.sendMessage(text, in: conversationID)
        draft = ""
    }
}

private struct MessageBubble: View {
    let message: DMMessage
    let isMine: Bool

    var body: some View {
        HStack {
            if isMine { Spacer(minLength: 60) }
            VStack(alignment: isMine ? .trailing : .leading, spacing: 2) {
                Text(message.text)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(isMine ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.quaternary))
                    .foregroundStyle(isMine ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                Text(shortRelativeDate(message.date))
                    .font(.caption2)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            if !isMine { Spacer(minLength: 60) }
        }
    }
}
