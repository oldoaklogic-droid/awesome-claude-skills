import SwiftUI

struct MessagesView: View {
    @EnvironmentObject private var store: AppStore
    @State private var selectedConversationID: UUID?
    @State private var draft = ""

    var body: some View {
        HSplitView {
            conversationList
                .frame(minWidth: 240, idealWidth: 280, maxWidth: 360)
            chatPane
                .frame(minWidth: 380, maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle("Messages")
        .onAppear {
            if selectedConversationID == nil {
                selectedConversationID = store.conversations.first?.id
            }
        }
    }

    // MARK: Conversation list

    private var conversationList: some View {
        List(selection: $selectedConversationID) {
            ForEach(store.conversations) { conversation in
                conversationRow(conversation)
                    .tag(conversation.id)
            }
        }
        .listStyle(.inset)
    }

    private func conversationRow(_ conversation: Conversation) -> some View {
        let partner = store.user(conversation.participantID)
        let last = conversation.messages.last
        return HStack(spacing: 10) {
            AvatarView(user: partner, size: 40)
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    UserNameLine(user: partner, showsHandle: false)
                    Spacer()
                    if let last {
                        Text(shortRelativeDate(last.date))
                            .font(.caption)
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

    // MARK: Chat pane

    @ViewBuilder
    private var chatPane: some View {
        if let conversationID = selectedConversationID,
           let conversation = store.conversations.first(where: { $0.id == conversationID }) {
            let partner = store.user(conversation.participantID)
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    AvatarView(user: partner, size: 28)
                    UserNameLine(user: partner)
                    Spacer()
                }
                .padding(12)
                Divider()

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(conversation.messages) { message in
                                MessageBubble(message: message,
                                              isMine: message.senderID == store.currentUserID)
                                    .id(message.id)
                            }
                        }
                        .padding(12)
                    }
                    .onChange(of: conversation.messages.count) {
                        if let lastID = conversation.messages.last?.id {
                            withAnimation { proxy.scrollTo(lastID, anchor: .bottom) }
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
                        .onSubmit(send)
                    Button {
                        send()
                    } label: {
                        Image(systemName: "paperplane.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(12)
            }
        } else {
            ContentUnavailableView("Select a message",
                                   systemImage: "envelope.open",
                                   description: Text("Choose a conversation to start chatting."))
        }
    }

    private func send() {
        guard let conversationID = selectedConversationID else { return }
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
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                Text(shortRelativeDate(message.date))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            if !isMine { Spacer(minLength: 60) }
        }
    }
}
