import SwiftUI

enum AppSection: String, CaseIterable, Identifiable, Hashable {
    case home, explore, notifications, messages, bookmarks, lists, communities, profile, settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: return "Home"
        case .explore: return "Explore"
        case .notifications: return "Notifications"
        case .messages: return "Messages"
        case .bookmarks: return "Bookmarks"
        case .lists: return "Lists"
        case .communities: return "Communities"
        case .profile: return "Profile"
        case .settings: return "Settings"
        }
    }

    var symbol: String {
        switch self {
        case .home: return "house"
        case .explore: return "magnifyingglass"
        case .notifications: return "bell"
        case .messages: return "envelope"
        case .bookmarks: return "bookmark"
        case .lists: return "list.bullet.rectangle"
        case .communities: return "person.3"
        case .profile: return "person"
        case .settings: return "gearshape"
        }
    }
}

/// Push destinations inside each section's NavigationStack.
enum Route: Hashable {
    case thread(UUID)   // post detail + replies
    case profile(UUID)  // user profile
}

struct ContentView: View {
    @EnvironmentObject private var store: AppStore
    @State private var selection: AppSection? = .home
    @State private var showCompose = false

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detail
        }
        .sheet(isPresented: $showCompose) {
            ComposeView(mode: .new)
        }
    }

    private var sidebar: some View {
        VStack(spacing: 0) {
            List(selection: $selection) {
                HStack(spacing: 8) {
                    Image(systemName: "dot.radiowaves.left.and.right")
                        .font(.title2.bold())
                        .foregroundStyle(Color.accentColor)
                    Text("PING IT")
                        .font(.title3.weight(.heavy))
                }
                .padding(.vertical, 8)

                ForEach(AppSection.allCases) { section in
                    NavigationLink(value: section) {
                        Label {
                            Text(section.title)
                        } icon: {
                            Image(systemName: section.symbol)
                        }
                        .badge(badge(for: section))
                    }
                }
            }
            .listStyle(.sidebar)

            Button {
                showCompose = true
            } label: {
                Label("Ping", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(12)
        }
        .navigationSplitViewColumnWidth(min: 200, ideal: 220)
    }

    private func badge(for section: AppSection) -> Int {
        switch section {
        case .notifications: return store.unreadNotificationCount
        case .messages: return store.unreadMessageCount
        default: return 0
        }
    }

    @ViewBuilder
    private var detail: some View {
        switch selection ?? .home {
        case .home: SectionStack { HomeView() }
        case .explore: SectionStack { ExploreView() }
        case .notifications: SectionStack { NotificationsView() }
        case .messages: MessagesView()
        case .bookmarks: SectionStack { BookmarksView() }
        case .lists: SectionStack { ListsView() }
        case .communities: SectionStack { CommunitiesView() }
        case .profile: SectionStack { ProfileView(userID: store.currentUserID) }
        case .settings: SectionStack { SettingsView() }
        }
    }
}

/// Wraps a section root in a NavigationStack that knows how to push
/// post threads and user profiles.
struct SectionStack<Root: View>: View {
    @ViewBuilder var root: () -> Root

    var body: some View {
        NavigationStack {
            root()
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .thread(let postID):
                        ThreadView(postID: postID)
                    case .profile(let userID):
                        ProfileView(userID: userID)
                    }
                }
        }
    }
}

// MARK: - Shared small views

struct AvatarView: View {
    let user: User
    var size: CGFloat = 40

    var body: some View {
        ZStack {
            Circle().fill(user.avatarColor.gradient)
            Image(systemName: user.avatarSymbol)
                .font(.system(size: size * 0.45, weight: .medium))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
    }
}

struct VerifiedBadge: View {
    let verification: Verification

    var body: some View {
        if let color = verification.badgeColor {
            Image(systemName: "checkmark.seal.fill")
                .font(.footnote)
                .foregroundStyle(color)
        }
    }
}

struct UserNameLine: View {
    let user: User
    var showsHandle = true

    var body: some View {
        HStack(spacing: 4) {
            Text(user.displayName)
                .font(.subheadline.bold())
                .lineLimit(1)
            VerifiedBadge(verification: user.verification)
            if showsHandle {
                Text("@\(user.handle)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }
}
