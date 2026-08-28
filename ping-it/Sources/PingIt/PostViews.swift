import SwiftUI
import UIKit

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
        .padding(.horizontal, 8)
        .contentShape(Rectangle())
        .hoverHighlight()
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
                UIPasteboard.general.string = post.text
            }
        } label: {
            Image(systemName: "ellipsis")
                .foregroundStyle(.secondary)
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
        }
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
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(tint.opacity(0.14))
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
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.accentColor.opacity(0.25))
                        .frame(width: max(proxy.size.width * fraction, 4))
                        .animation(Motion.smooth, value: fraction)
                }
            }
            .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(.quaternary.opacity(0.3)))
        } else {
            Button {
                withAnimation(Motion.smooth) {
                    store.vote(postID: post.id, optionID: option.id)
                }
            } label: {
                Text(option.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.accentColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(Color.accentColor.opacity(0.5), lineWidth: 1.5)
                    )
                    .contentShape(Rectangle())
            }
            .buttonStyle(PressableStyle())
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

    @State private var burstTrigger = 0

    private var isLiked: Bool { store.likedPostIDs.contains(post.id) }
    private var isReposted: Bool { store.repostedPostIDs.contains(post.id) }
    private var isBookmarked: Bool { store.bookmarkedPostIDs.contains(post.id) }

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
            likeButton
            Spacer()
            actionButton(symbol: "chart.bar.xaxis", count: post.viewCount, tint: .secondary) {}
            Spacer()
            bookmarkButton
            actionButton(symbol: "square.and.arrow.up", count: nil, tint: .secondary) {
                let author = store.user(post.authorID)
                UIPasteboard.general.string = "pingit://\(author.handle)/status/\(post.id.uuidString)"
            }
        }
        .padding(.top, 2)
        .frame(maxWidth: 420, alignment: .leading)
    }

    private var likeButton: some View {
        Button {
            if !isLiked { burstTrigger += 1 }
            withAnimation(Motion.standard) { store.toggleLike(post.id) }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: isLiked ? "heart.fill" : "heart")
                    .scaleEffect(isLiked ? 1.1 : 1)
                    .overlay(HeartBurstView(trigger: burstTrigger))
                animatedCount(post.likeCount)
            }
            .foregroundStyle(isLiked ? Color.pink : Color.secondary)
        }
        .buttonStyle(PressableStyle(scale: 0.9))
        .animation(Motion.standard, value: isLiked)
    }

    private var bookmarkButton: some View {
        Button {
            withAnimation(Motion.standard) { store.toggleBookmark(post.id) }
        } label: {
            Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                .foregroundStyle(isBookmarked ? Color.accentColor : Color.secondary)
                .symbolEffect(.bounce, value: isBookmarked)
        }
        .buttonStyle(PressableStyle(scale: 0.9))
    }

    private var repostMenu: some View {
        Menu {
            Button(isReposted ? "Undo repost" : "Repost") {
                withAnimation(Motion.standard) { store.toggleRepost(post.id) }
            }
            Button("Quote") { composeMode = .quote(post) }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "arrow.2.squarepath")
                    .rotationEffect(.degrees(isReposted ? 180 : 0))
                animatedCount(post.repostCount)
            }
            .foregroundStyle(isReposted ? Color.green : Color.secondary)
        }
        .fixedSize()
        .animation(Motion.standard, value: isReposted)
    }

    /// Counts roll between values instead of jumping; tabular digits stop jitter.
    private func animatedCount(_ value: Int) -> some View {
        Text(compactCount(value))
            .font(.caption)
            .monospacedDigit()
            .contentTransition(.numericText())
            .animation(Motion.standard, value: value)
            .opacity(value > 0 ? 1 : 0)
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
        .buttonStyle(PressableStyle(scale: 0.9))
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
            EmptyStateView(symbol: "trash",
                           title: "This ping is gone",
                           message: "It was deleted by its author. The conversation moved on — you should too.")
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
                withAnimation(Motion.standard) {
                    store.createPost(text: text, replyTo: post.id)
                }
                replyText = ""
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(replyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(replyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
            .animation(Motion.fade, value: replyText.isEmpty)
        }
        .padding(.vertical, 10)
    }
}
