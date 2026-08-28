import SwiftUI

struct ExploreView: View {
    @EnvironmentObject private var store: AppStore
    @State private var query = ""

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespaces)
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                if trimmedQuery.isEmpty {
                    trendsSection
                    whoToFollowSection
                } else {
                    searchResults
                }
            }
            .padding(.horizontal, 16)
        }
        .navigationTitle("Explore")
        .searchable(text: $query, prompt: "Search PING IT")
    }

    // MARK: Trends

    private var trendsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Trends for you")
                .font(.title2.bold())
                .padding(.vertical, 12)

            ForEach(Array(store.trends.enumerated()), id: \.element.id) { index, trend in
                Button {
                    query = trend.topic
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(index + 1) · \(trend.category)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(trend.topic)
                            .font(.headline)
                        Text("\(compactCount(trend.postCount)) pings")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PressableStyle(scale: 0.98))
                .padding(.vertical, 8)
                .hoverHighlight()
                Divider()
            }
        }
    }

    private var whoToFollowSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Who to follow")
                .font(.title2.bold())
                .padding(.vertical, 12)

            ForEach(store.users.filter { $0.id != store.currentUserID && !store.isFollowing($0.id) }) { user in
                UserRow(user: user)
                Divider()
            }
        }
    }

    // MARK: Search

    private var searchResults: some View {
        let userHits = store.searchUsers(trimmedQuery)
        let postHits = store.searchPosts(trimmedQuery)

        return VStack(alignment: .leading, spacing: 0) {
            if !userHits.isEmpty {
                Text("People")
                    .font(.title3.bold())
                    .padding(.vertical, 10)
                ForEach(userHits) { user in
                    UserRow(user: user)
                    Divider()
                }
            }

            Text("Pings")
                .font(.title3.bold())
                .padding(.vertical, 10)

            if postHits.isEmpty {
                EmptyStateView(symbol: "magnifyingglass",
                               title: "No pings for \u{201C}\(trimmedQuery)\u{201D}",
                               message: "Try a different word, or start the conversation yourself.")
            } else {
                ForEach(postHits) { post in
                    PostCard(post: post)
                    Divider()
                }
            }
        }
    }
}

/// A compact user row with a follow button, used in Explore, lists, and profiles.
struct UserRow: View {
    @EnvironmentObject private var store: AppStore
    let user: User

    var body: some View {
        HStack(spacing: 10) {
            NavigationLink(value: Route.profile(user.id)) {
                HStack(spacing: 10) {
                    AvatarView(user: user)
                    VStack(alignment: .leading, spacing: 2) {
                        UserNameLine(user: user, showsHandle: false)
                        Text("@\(user.handle)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(user.bio)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer()

            if user.id != store.currentUserID {
                FollowButton(userID: user.id)
            }
        }
        .padding(.vertical, 8)
    }
}

/// Morphs between filled "Follow" and outlined "Following" with a width spring.
struct FollowButton: View {
    @EnvironmentObject private var store: AppStore
    let userID: UUID

    var body: some View {
        let following = store.isFollowing(userID)
        Button {
            withAnimation(Motion.standard) { store.toggleFollow(userID) }
        } label: {
            Text(following ? "Following" : "Follow")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(following ? Color.primary : Color.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Capsule().fill(following ? Color.clear : Color.accentColor))
                .overlay(Capsule().strokeBorder(.quaternary, lineWidth: following ? 1 : 0))
        }
        .buttonStyle(PressableStyle())
        .animation(Motion.standard, value: following)
    }
}
