import SwiftUI

// MARK: - Bookmarks

struct BookmarksView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                if store.bookmarkedPosts.isEmpty {
                    ContentUnavailableView("Save pings for later",
                                           systemImage: "bookmark",
                                           description: Text("Bookmark pings to easily find them again in the future."))
                        .padding(.top, 80)
                } else {
                    ForEach(store.bookmarkedPosts) { post in
                        PostCard(post: post)
                        Divider()
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .navigationTitle("Bookmarks")
    }
}

// MARK: - Lists

struct ListsView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                Text("Your Lists")
                    .font(.title2.bold())
                    .padding(.vertical, 12)

                ForEach(store.lists) { list in
                    ListRow(list: list)
                    Divider()
                }
            }
            .padding(.horizontal, 16)
        }
        .navigationTitle("Lists")
    }
}

private struct ListRow: View {
    @EnvironmentObject private var store: AppStore
    let list: UserList
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation { isExpanded.toggle() }
            } label: {
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.accentColor.opacity(0.2))
                        .overlay(Image(systemName: "list.bullet").foregroundStyle(Color.accentColor))
                        .frame(width: 44, height: 44)
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(list.name).font(.headline)
                            if list.isPrivate {
                                Image(systemName: "lock.fill")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Text(list.about)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("\(list.memberIDs.count) members")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                ForEach(list.memberIDs, id: \.self) { memberID in
                    UserRow(user: store.user(memberID))
                        .padding(.leading, 32)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Communities

struct CommunitiesView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                Text("Discover Communities")
                    .font(.title2.bold())
                    .padding(.vertical, 12)

                ForEach(store.communities) { community in
                    CommunityCard(community: community)
                    Divider()
                }
            }
            .padding(.horizontal, 16)
        }
        .navigationTitle("Communities")
    }
}

private struct CommunityCard: View {
    @EnvironmentObject private var store: AppStore
    let community: Community
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.accentColor.gradient)
                    .overlay(Image(systemName: community.symbol).font(.title3).foregroundStyle(.white))
                    .frame(width: 48, height: 48)
                VStack(alignment: .leading, spacing: 2) {
                    Text(community.name).font(.headline)
                    Text(community.about)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("\(compactCount(community.memberCount)) members")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(community.isJoined ? "Joined" : "Join") {
                    store.toggleJoin(community.id)
                }
                .buttonStyle(.bordered)
                .tint(community.isJoined ? .secondary : .accentColor)
            }

            let communityPosts = store.posts(in: community.id)
            if !communityPosts.isEmpty {
                Button(isExpanded ? "Hide posts" : "Show recent posts (\(communityPosts.count))") {
                    withAnimation { isExpanded.toggle() }
                }
                .font(.caption)
                .buttonStyle(.plain)
                .foregroundStyle(Color.accentColor)

                if isExpanded {
                    ForEach(communityPosts) { post in
                        PostCard(post: post)
                            .padding(.leading, 24)
                    }
                }
            }
        }
        .padding(.vertical, 10)
    }
}

// MARK: - Settings

struct SettingsView: View {
    @EnvironmentObject private var store: AppStore
    @AppStorage("appearance") private var appearance: Appearance = .system

    var body: some View {
        Form {
            Section("Your account") {
                HStack(spacing: 12) {
                    AvatarView(user: store.currentUser, size: 44)
                    VStack(alignment: .leading) {
                        UserNameLine(user: store.currentUser, showsHandle: false)
                        Text("@\(store.currentUser.handle)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Premium") {
                Toggle(isOn: $store.isPremium) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("PING IT Premium")
                        Text("Unlocks the verified badge, editing pings, and a 25,000 character limit.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                LabeledContent("Character limit", value: "\(store.characterLimit)")
            }

            Section("Display") {
                Picker("Appearance", selection: $appearance) {
                    ForEach(Appearance.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("About") {
                LabeledContent("Version", value: "1.0")
                LabeledContent("Made with", value: "SwiftUI")
                Text("PING IT is a demo social app. All accounts and posts are fictional sample data stored locally on this Mac.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
        .onChange(of: store.isPremium) { _, premium in
            // Keep the profile badge in sync with the Premium toggle.
            if let index = store.users.firstIndex(where: { $0.id == store.currentUserID }) {
                store.users[index].verification = premium ? .blue : .none
            }
        }
    }
}
