import SwiftUI

struct ProfileView: View {
    enum Tab: String, CaseIterable, Identifiable {
        case posts = "Pings"
        case replies = "Replies"
        case likes = "Likes"
        var id: String { rawValue }
    }

    @EnvironmentObject private var store: AppStore
    let userID: UUID
    @State private var tab: Tab = .posts
    @State private var showEditProfile = false

    private var user: User { store.user(userID) }
    private var isMe: Bool { userID == store.currentUserID }

    private var tabPosts: [Post] {
        switch tab {
        case .posts: return store.posts(by: userID)
        case .replies: return store.repliesBy(userID)
        case .likes: return isMe ? store.likedPosts() : []
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                banner
                header
                Divider().padding(.top, 12)

                Picker("Tab", selection: $tab) {
                    ForEach(Tab.allCases) { t in
                        Text(t.rawValue).tag(t)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .padding(.vertical, 8)
                .padding(.horizontal, 16)

                ForEach(tabPosts) { post in
                    PostCard(post: post)
                        .padding(.horizontal, 16)
                    Divider()
                }

                if tabPosts.isEmpty {
                    ContentUnavailableView(emptyTitle, systemImage: "text.bubble")
                        .padding(.top, 40)
                }
            }
        }
        .navigationTitle(user.displayName)
        .sheet(isPresented: $showEditProfile) {
            EditProfileView()
        }
    }

    private var emptyTitle: String {
        switch tab {
        case .posts: return "No pings yet"
        case .replies: return "No replies yet"
        case .likes: return isMe ? "No likes yet" : "Likes are private"
        }
    }

    private var banner: some View {
        Rectangle()
            .fill(user.bannerColor.gradient)
            .frame(height: 120)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .bottom) {
                AvatarView(user: user, size: 80)
                    .overlay(Circle().stroke(.background, lineWidth: 4))
                    .offset(y: -30)
                    .padding(.bottom, -30)
                Spacer()
                if isMe {
                    Button("Edit profile") { showEditProfile = true }
                        .buttonStyle(.bordered)
                } else {
                    FollowButton(userID: userID)
                }
            }

            HStack(spacing: 4) {
                Text(user.displayName).font(.title2.bold())
                VerifiedBadge(verification: user.verification)
            }
            Text("@\(user.handle)")
                .foregroundStyle(.secondary)

            if !user.bio.isEmpty {
                Text(styledPostText(user.bio))
            }

            HStack(spacing: 14) {
                if !user.location.isEmpty {
                    Label(user.location, systemImage: "mappin.and.ellipse")
                }
                if !user.website.isEmpty {
                    Label(user.website, systemImage: "link")
                        .foregroundStyle(Color.accentColor)
                }
                Label("Joined \(user.joinDate.formatted(.dateTime.month(.wide).year()))",
                      systemImage: "calendar")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                (Text("\(compactCount(user.followingCount)) ").bold() + Text("Following").foregroundStyle(.secondary))
                (Text("\(compactCount(user.followerCount)) ").bold() + Text("Followers").foregroundStyle(.secondary))
            }
            .font(.subheadline)
        }
        .padding(.horizontal, 16)
    }
}

struct EditProfileView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var displayName = ""
    @State private var bio = ""
    @State private var location = ""
    @State private var website = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Edit profile").font(.headline)
            Form {
                TextField("Name", text: $displayName)
                TextField("Bio", text: $bio, axis: .vertical)
                    .lineLimit(2...4)
                TextField("Location", text: $location)
                TextField("Website", text: $website)
            }
            .formStyle(.grouped)
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Save") {
                    store.updateProfile(displayName: displayName, bio: bio,
                                        location: location, website: website)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(displayName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 440, height: 380)
        .onAppear {
            let me = store.currentUser
            displayName = me.displayName
            bio = me.bio
            location = me.location
            website = me.website
        }
    }
}
