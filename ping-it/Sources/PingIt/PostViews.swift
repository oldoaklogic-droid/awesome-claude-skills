import SwiftUI
import AppKit

// MARK: - Post card

struct PostCard: View {
    @EnvironmentObject private var store: AppStore
    let post: Post
    /// Threads render the focused post larger, without a nav link on itself.
    var isDetail = false

    @State private var composeMode: ComposeView.Mode?

    private var author: User { store.user(post.authorID) }

    var body: some View {
        Group {
            if isDetail {
                card
            } else {
                NavigationLink(value: Route.thread(post.id)) {
                    card
                }
                .buttonStyle(.plain)
            }
        }
        .sheet(item: $composeMode) { mode in
            ComposeView(mode: mode)
        }
    }

    private var card: some View {
        HStack(alignment: .top, spacing: 12) {
            NavigationLink(value: Route.profile(author.id)) {
                AvatarView(user: author)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 6) {
                header
                Text(styledPostText(post.text))
                    .font(isDetail ? .title3 : .body)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)

                if !post.mediaSymbols.isEmpty {
                    MediaStrip(symbols: post.mediaSymbols, tint: author.avatarColor)
                }

                if post.poll != nil {
                    PollView(post: post)
                }

                if let quotedID = post.quotedPostID, let quoted = store.post(quotedID) {
                    QuotedPostView(post: quoted)
                }

                ActionBar(post: post, composeMode: $composeMode)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
    }

    private var header: some View {
        HStack(spacing: 4) {
            UserNameLine(user: author)
            Text("· \(shortRelativeDate(post.date))")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if post.isEdited {
                Text("· Edited")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            postMenu
        }
    }

    private var postMenu: some View {
        Menu {
            if post.authorID == store.currentUserID {
                if store.isPremium {
                    Button("Edit ping") { composeMode = .edit(post) }
                }
                Button("Delete ping", role: .destructive) { store.deletePost(post.id) }
            } else {
                if store.isFollowing(post.authorID) {
                    Button("Unfollow @\(author.handle)") { store.toggleFollow(post.authorID) }
                } else {
                    Button("Follow @\(author.handle)") { store.toggleFollow(post.authorID) }
                }
                Button("Mute @\(author.handle)") {}
                Button("Block @\(author.handle)", role: .destructive) {}
                Button("Report ping") {}
            }
            Divider()
            Button("Copy text") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(post.text, forType: .string)
            }
        } label: {
            Image(systemName: "ellipsis")
                .foregroundStyle(.secondary)
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }
}

// MARK: - Media placeholder

struct MediaStrip: View {
    let symbols: [String]
    let tint: Color

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(symbols.enumerated()), id: \.offset) { _, symbol in
                RoundedRectangle(cornerRadius: 12)
                    .fill(tint.opacity(0.15).gradient)
                    .overlay {
                        Image(systemName: symbol)
                            .font(.system(size: 36))
                            .foregroundStyle(tint)
                    }
                    .frame(height: 140)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

// MARK: - Poll

struct PollView: View {
    @EnvironmentObject private var store: AppStore
    let post: Post

    var body: some View {
        if let poll = post.poll {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(poll.options) { option in
                    pollRow(poll: poll, option: option)
                }
                Text("\(compactCount(poll.totalVotes)) votes · \(poll.isClosed ? "Final results" : "Ends \(shortRelativeDate(poll.endDate)) from now")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 2)
        }
    }

    @ViewBuilder
    private func pollRow(poll: Poll, option: PollOption) -> some View {
        let hasVoted = poll.votedOptionID != nil || poll.isClosed
        let fraction = poll.totalVotes > 0 ? Double(option.votes) / Double(poll.totalVotes) : 0

        if hasVoted {
            HStack {
                Text(option.title)
                    .fontWeight(poll.votedOptionID == option.id ? .bold : .regular)
                if poll.votedOptionID == option.id {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.accentColor)
                }
                Spacer()
                Text("\(Int((fraction * 100).rounded()))%")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline)
            .padding(8)
            .background(alignment: .leading) {
                GeometryReader { proxy in
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.accentColor.opacity(0.25))
                        .frame(width: max(proxy.size.width * fraction, 4))
                }
            }
            .background(RoundedRectangle(cornerRadius: 6).fill(.quaternary.opacity(0.3)))
        } else {
            Button {
                store.vote(postID: post.id, optionID: option.id)
            } label: {
                Text(option.title)
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(6)
            }
            .buttonStyle(.bordered)
            .tint(.accentColor)
        }
    }
}

// MARK: - Quoted post

struct QuotedPostView: View {
    @EnvironmentObject private var store: AppStore
    let post: Post

    var body: some View {
        let author = store.user(post.authorID)
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                AvatarView(user: author, size: 20)
                UserNameLine(user: author)
                Text("· \(shortRelativeDate(post.date))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Text(styledPostText(post.text))
                .font(.subheadline)
                .lineLimit(4)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(.quaternary))
    }
}

// MARK: - Action bar (reply / repost / like / views / bookmark / share)

struct ActionBar: View {
    @EnvironmentObject private var store: AppStore
    let post: Post
    @Binding var composeMode: ComposeView.Mode?

    var body: some View {
        HStack(spacing: 0) {
            actionButton(symbol: "bubble.left",
                         count: store.replyCount(for: post.id),
                         tint: .secondary) {
                composeMode = .reply(post)
            }
            Spacer()
            repostMenu
            Spacer()
            actionButton(symbol: store.likedPostIDs.contains(post.id) ? "heart.fill" : "heart",
                         count: post.likeCount,
                         tint: store.likedPostIDs.contains(post.id) ? .pink : .secondary) {
                store.toggleLike(post.id)
            }
            Spacer()
            actionButton(symbol: "chart.bar.xaxis", count: post.viewCount, tint: .secondary) {}
            Spacer()
            actionButton(symbol: store.bookmarkedPostIDs.contains(post.id) ? "bookmark.fill" : "bookmark",
                         count: nil,
                         tint: store.bookmarkedPostIDs.contains(post.id) ? .accentColor : .secondary) {
                store.toggleBookmark(post.id)
            }
            actionButton(symbol: "square.and.arrow.up", count: nil, tint: .secondary) {
                let author = store.user(post.authorID)
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString("pingit://\(author.handle)/status/\(post.id.uuidString)", forType: .string)
            }
        }
        .padding(.top, 2)
        .frame(maxWidth: 420, alignment: .leading)
    }

    private var repostMenu: some View {
        let reposted = store.repostedPostIDs.contains(post.id)
        return Menu {
            Button(reposted ? "Undo repost" : "Repost") { store.toggleRepost(post.id) }
            Button("Quote") { composeMode = .quote(post) }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "arrow.2.squarepath")
                Text(compactCount(post.repostCount))
                    .font(.caption)
                    .monospacedDigit()
            }
            .foregroundStyle(reposted ? Color.green : Color.secondary)
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }

    private func actionButton(symbol: String, count: Int?, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: symbol)
                if let count, count > 0 {
                    Text(compactCount(count))
                        .font(.caption)
                        .monospacedDigit()
                }
            }
            .foregroundStyle(tint)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Thread (post detail)

struct ThreadView: View {
    @EnvironmentObject private var store: AppStore
    let postID: UUID
    @State private var replyText = ""

    var body: some View {
        if let post = store.post(postID) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    if let parentID = post.replyToID, let parent = store.post(parentID) {
                        PostCard(post: parent)
                        Divider()
                    }

                    PostCard(post: post, isDetail: true)

                    HStack(spacing: 16) {
                        statLabel(compactCount(post.viewCount), "Views")
                        statLabel(compactCount(post.repostCount), "Reposts")
                        statLabel(compactCount(post.likeCount), "Likes")
                        statLabel(compactCount(store.replyCount(for: post.id)), "Replies")
                    }
                    .padding(.vertical, 8)

                    Divider()
                    replyComposer(to: post)
                    Divider()

                    ForEach(store.replies(to: post.id)) { reply in
                        PostCard(post: reply)
                        Divider()
                    }
                }
                .padding(.horizontal, 16)
            }
            .navigationTitle("Ping")
        } else {
            ContentUnavailableView("This ping was deleted", systemImage: "trash")
        }
    }

    private func statLabel(_ value: String, _ label: String) -> some View {
        HStack(spacing: 4) {
            Text(value).font(.subheadline.bold()).monospacedDigit()
            Text(label).font(.subheadline).foregroundStyle(.secondary)
        }
    }

    private func replyComposer(to post: Post) -> some View {
        HStack(alignment: .top, spacing: 10) {
            AvatarView(user: store.currentUser, size: 32)
            TextField("Ping your reply", text: $replyText, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...5)
            Button("Reply") {
                let text = replyText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !text.isEmpty else { return }
                store.createPost(text: text, replyTo: post.id)
                replyText = ""
            }
            .buttonStyle(.borderedProminent)
            .disabled(replyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.vertical, 10)
    }
}
