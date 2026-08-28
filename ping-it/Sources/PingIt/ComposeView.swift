import SwiftUI

/// The compose sheet, used for new pings, replies, quotes, and (Premium) edits.
struct ComposeView: View {
    enum Mode: Identifiable {
        case new
        case reply(Post)
        case quote(Post)
        case edit(Post)

        var id: String {
            switch self {
            case .new: return "new"
            case .reply(let p): return "reply-\(p.id)"
            case .quote(let p): return "quote-\(p.id)"
            case .edit(let p): return "edit-\(p.id)"
            }
        }
    }

    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    let mode: Mode
    @State private var text = ""
    @State private var showPoll = false
    @State private var pollOptions = ["", ""]

    private var title: String {
        switch mode {
        case .new: return "New Ping"
        case .reply: return "Reply"
        case .quote: return "Quote Ping"
        case .edit: return "Edit Ping"
        }
    }

    private var actionLabel: String {
        switch mode {
        case .edit: return "Save"
        case .reply: return "Reply"
        default: return "Ping"
        }
    }

    private var remaining: Int { store.characterLimit - text.count }

    private var canSubmit: Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && remaining >= 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title).font(.headline)
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }

            if case .reply(let parent) = mode {
                contextRow(label: "Replying to", post: parent)
            }

            HStack(alignment: .top, spacing: 10) {
                AvatarView(user: store.currentUser, size: 36)
                TextEditor(text: $text)
                    .font(.title3)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 120)
                    .overlay(alignment: .topLeading) {
                        if text.isEmpty {
                            Text(placeholder)
                                .font(.title3)
                                .foregroundStyle(.tertiary)
                                .padding(.top, 8)
                                .padding(.leading, 5)
                                .allowsHitTesting(false)
                        }
                    }
            }

            if case .quote(let quoted) = mode {
                QuotedPostView(post: quoted)
            }

            if showPoll {
                pollEditor
            }

            HStack(spacing: 14) {
                Group {
                    Image(systemName: "photo")
                    Image(systemName: "photo.stack")
                    Button {
                        withAnimation { showPoll.toggle() }
                    } label: {
                        Image(systemName: "chart.bar.yaxis")
                    }
                    .buttonStyle(.plain)
                    .disabled(!canAddPoll)
                    Image(systemName: "face.smiling")
                    Image(systemName: "calendar.badge.clock")
                    Image(systemName: "mappin.and.ellipse")
                }
                .foregroundStyle(Color.accentColor)

                Spacer()

                characterRing

                Button(actionLabel) { submit() }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(!canSubmit)
                    .opacity(canSubmit ? 1 : 0.5)
                    .animation(Motion.fade, value: canSubmit)
                    .keyboardShortcut(.return, modifiers: .command)
            }
        }
        .padding(20)
        .presentationDragIndicator(.visible)
        .onAppear {
            if case .edit(let post) = mode { text = post.text }
        }
    }

    private var placeholder: String {
        switch mode {
        case .reply: return "Ping your reply"
        default: return "What is happening?!"
        }
    }

    private var canAddPoll: Bool {
        switch mode {
        case .new: return true
        default: return false
        }
    }

    private var characterRing: some View {
        let limit = store.characterLimit
        let progress = min(Double(text.count) / Double(limit), 1)
        return ZStack {
            Circle().stroke(.quaternary, lineWidth: 3)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(remaining < 0 ? Color.red : (remaining < 20 ? .orange : Color.accentColor),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(Motion.standard, value: progress)
            if remaining < 40 {
                Text("\(remaining)")
                    .font(.caption2)
                    .monospacedDigit()
                    .foregroundStyle(remaining < 0 ? .red : .secondary)
            }
        }
        .frame(width: 26, height: 26)
    }

    private var pollEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(pollOptions.indices, id: \.self) { index in
                TextField("Choice \(index + 1)", text: $pollOptions[index])
                    .textFieldStyle(.roundedBorder)
            }
            HStack {
                Button("Add choice") { pollOptions.append("") }
                    .disabled(pollOptions.count >= 4)
                Spacer()
                Button("Remove poll", role: .destructive) {
                    withAnimation {
                        showPoll = false
                        pollOptions = ["", ""]
                    }
                }
            }
            .font(.caption)
        }
        .padding(10)
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(.quaternary))
    }

    private func contextRow(label: String, post: Post) -> some View {
        let author = store.user(post.authorID)
        return HStack(spacing: 6) {
            Text(label)
            Text("@\(author.handle)").foregroundStyle(Color.accentColor)
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }

    private func submit() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        switch mode {
        case .new:
            store.createPost(text: trimmed, pollOptions: showPoll ? pollOptions : [])
        case .reply(let parent):
            store.createPost(text: trimmed, replyTo: parent.id)
        case .quote(let quoted):
            store.createPost(text: trimmed, quoting: quoted.id)
        case .edit(let post):
            store.editPost(post.id, newText: trimmed)
        }
        dismiss()
    }
}
