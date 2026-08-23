import SwiftUI

/// Central observable state for PING IT. Everything is kept in memory,
/// seeded from `SampleData`, so the app is fully interactive offline.
@MainActor
final class AppStore: ObservableObject {

    // MARK: Data

    @Published var users: [User]
    @Published var posts: [Post]
    @Published var notifications: [AppNotification]
    @Published var conversations: [Conversation]
    @Published var trends: [Trend]
    @Published var communities: [Community]
    @Published var lists: [UserList]

    @Published var currentUserID: UUID
    @Published var likedPostIDs: Set<UUID>
    @Published var repostedPostIDs: Set<UUID> = []
    @Published var bookmarkedPostIDs: Set<UUID>
    @Published var followedUserIDs: Set<UUID>

    /// Premium unlocks post editing and the 25 000 character limit,
    /// mirroring X Premium.
    @Published var isPremium: Bool = true

    init() {
        let seed = SampleData.make()
        users = seed.users
        posts = seed.posts
        notifications = seed.notifications
        conversations = seed.conversations
        trends = seed.trends
        communities = seed.communities
        lists = seed.lists
        currentUserID = seed.currentUserID
        likedPostIDs = seed.likedPostIDs
        bookmarkedPostIDs = seed.bookmarkedPostIDs
        followedUserIDs = seed.followedUserIDs
    }

    // MARK: Lookups

    var currentUser: User { user(currentUserID) }

    func user(_ id: UUID) -> User {
        users.first { $0.id == id } ?? currentUser
    }

    func post(_ id: UUID) -> Post? {
        posts.first { $0.id == id }
    }

    func replyCount(for postID: UUID) -> Int {
        posts.filter { $0.replyToID == postID }.count
    }

    func replies(to postID: UUID) -> [Post] {
        posts.filter { $0.replyToID == postID }.sorted { $0.date < $1.date }
    }

    var characterLimit: Int { isPremium ? 25_000 : 280 }

    // MARK: Feeds

    /// "For You": every top-level post, ranked by engagement.
    var forYouFeed: [Post] {
        posts
            .filter { $0.replyToID == nil }
            .sorted { score($0) > score($1) }
    }

    /// "Following": top-level posts from followed accounts (and yourself),
    /// in reverse-chronological order.
    var followingFeed: [Post] {
        posts
            .filter { $0.replyToID == nil }
            .filter { followedUserIDs.contains($0.authorID) || $0.authorID == currentUserID }
            .sorted { $0.date > $1.date }
    }

    private func score(_ post: Post) -> Double {
        let engagement = Double(post.likeCount * 3 + post.repostCount * 4 + replyCount(for: post.id) * 2)
        let ageHours = max(Date.now.timeIntervalSince(post.date) / 3_600, 0.5)
        return engagement / ageHours + Double(post.viewCount) / 10_000
    }

    var bookmarkedPosts: [Post] {
        posts.filter { bookmarkedPostIDs.contains($0.id) }.sorted { $0.date > $1.date }
    }

    func posts(by userID: UUID) -> [Post] {
        posts.filter { $0.authorID == userID && $0.replyToID == nil }.sorted { $0.date > $1.date }
    }

    func repliesBy(_ userID: UUID) -> [Post] {
        posts.filter { $0.authorID == userID && $0.replyToID != nil }.sorted { $0.date > $1.date }
    }

    func likedPosts() -> [Post] {
        posts.filter { likedPostIDs.contains($0.id) }.sorted { $0.date > $1.date }
    }

    func posts(in communityID: UUID) -> [Post] {
        posts.filter { $0.communityID == communityID }.sorted { $0.date > $1.date }
    }

    // MARK: Post actions

    func toggleLike(_ postID: UUID) {
        guard let index = posts.firstIndex(where: { $0.id == postID }) else { return }
        if likedPostIDs.contains(postID) {
            likedPostIDs.remove(postID)
            posts[index].likeCount = max(0, posts[index].likeCount - 1)
        } else {
            likedPostIDs.insert(postID)
            posts[index].likeCount += 1
        }
    }

    func toggleRepost(_ postID: UUID) {
        guard let index = posts.firstIndex(where: { $0.id == postID }) else { return }
        if repostedPostIDs.contains(postID) {
            repostedPostIDs.remove(postID)
            posts[index].repostCount = max(0, posts[index].repostCount - 1)
        } else {
            repostedPostIDs.insert(postID)
            posts[index].repostCount += 1
        }
    }

    func toggleBookmark(_ postID: UUID) {
        if bookmarkedPostIDs.contains(postID) {
            bookmarkedPostIDs.remove(postID)
        } else {
            bookmarkedPostIDs.insert(postID)
        }
    }

    @discardableResult
    func createPost(text: String,
                    pollOptions: [String] = [],
                    replyTo: UUID? = nil,
                    quoting: UUID? = nil,
                    communityID: UUID? = nil) -> Post {
        var poll: Poll?
        let cleanOptions = pollOptions.map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        if cleanOptions.count >= 2 {
            poll = Poll(options: cleanOptions.map { PollOption(id: UUID(), title: $0, votes: 0) },
                        endDate: Date.now.addingTimeInterval(86_400),
                        votedOptionID: nil)
        }
        let post = Post(id: UUID(),
                        authorID: currentUserID,
                        text: text,
                        date: .now,
                        likeCount: 0,
                        repostCount: 0,
                        viewCount: Int.random(in: 20...400),
                        replyToID: replyTo,
                        quotedPostID: quoting,
                        poll: poll,
                        communityID: communityID)
        posts.insert(post, at: 0)
        return post
    }

    func editPost(_ postID: UUID, newText: String) {
        guard isPremium,
              let index = posts.firstIndex(where: { $0.id == postID }),
              posts[index].authorID == currentUserID else { return }
        posts[index].text = newText
        posts[index].isEdited = true
    }

    func deletePost(_ postID: UUID) {
        posts.removeAll { $0.id == postID || $0.replyToID == postID }
        likedPostIDs.remove(postID)
        repostedPostIDs.remove(postID)
        bookmarkedPostIDs.remove(postID)
    }

    func vote(postID: UUID, optionID: UUID) {
        guard let index = posts.firstIndex(where: { $0.id == postID }),
              var poll = posts[index].poll,
              poll.votedOptionID == nil,
              !poll.isClosed,
              let optionIndex = poll.options.firstIndex(where: { $0.id == optionID }) else { return }
        poll.options[optionIndex].votes += 1
        poll.votedOptionID = optionID
        posts[index].poll = poll
    }

    // MARK: Social graph

    func isFollowing(_ userID: UUID) -> Bool {
        followedUserIDs.contains(userID)
    }

    func toggleFollow(_ userID: UUID) {
        guard userID != currentUserID else { return }
        guard let index = users.firstIndex(where: { $0.id == userID }) else { return }
        if followedUserIDs.contains(userID) {
            followedUserIDs.remove(userID)
            users[index].followerCount = max(0, users[index].followerCount - 1)
        } else {
            followedUserIDs.insert(userID)
            users[index].followerCount += 1
        }
    }

    func updateProfile(displayName: String, bio: String, location: String, website: String) {
        guard let index = users.firstIndex(where: { $0.id == currentUserID }) else { return }
        users[index].displayName = displayName
        users[index].bio = bio
        users[index].location = location
        users[index].website = website
    }

    // MARK: Notifications

    var unreadNotificationCount: Int {
        notifications.filter { !$0.isRead }.count
    }

    func markNotificationsRead() {
        for index in notifications.indices {
            notifications[index].isRead = true
        }
    }

    // MARK: Messages

    var unreadMessageCount: Int {
        conversations.reduce(0) { $0 + $1.unreadCount }
    }

    func markConversationRead(_ conversationID: UUID) {
        guard let index = conversations.firstIndex(where: { $0.id == conversationID }) else { return }
        conversations[index].unreadCount = 0
    }

    func sendMessage(_ text: String, in conversationID: UUID) {
        guard let index = conversations.firstIndex(where: { $0.id == conversationID }) else { return }
        let message = DMMessage(id: UUID(), senderID: currentUserID, text: text, date: .now)
        conversations[index].messages.append(message)

        // Playful canned reply so the conversation feels alive.
        let partnerID = conversations[index].participantID
        let replies = [
            "Ha, good one 😄",
            "Totally agree.",
            "Wait, really? Tell me more.",
            "Pinging you back later — in a meeting.",
            "👀",
            "That deserves a repost."
        ]
        let convID = conversationID
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(2))
            guard let self, let idx = self.conversations.firstIndex(where: { $0.id == convID }) else { return }
            let reply = DMMessage(id: UUID(), senderID: partnerID, text: replies.randomElement() ?? "👍", date: .now)
            self.conversations[idx].messages.append(reply)
        }
    }

    // MARK: Communities

    func toggleJoin(_ communityID: UUID) {
        guard let index = communities.firstIndex(where: { $0.id == communityID }) else { return }
        communities[index].isJoined.toggle()
        communities[index].memberCount += communities[index].isJoined ? 1 : -1
    }

    // MARK: Search

    func searchUsers(_ query: String) -> [User] {
        let q = query.lowercased()
        guard !q.isEmpty else { return [] }
        return users.filter {
            $0.handle.lowercased().contains(q) || $0.displayName.lowercased().contains(q)
        }
    }

    func searchPosts(_ query: String) -> [Post] {
        let q = query.lowercased()
        guard !q.isEmpty else { return [] }
        return posts.filter { $0.text.lowercased().contains(q) }.sorted { $0.date > $1.date }
    }
}
