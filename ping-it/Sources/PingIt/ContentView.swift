import SwiftUI

/// Push destinations inside each tab's NavigationStack.
enum Route: Hashable {
    case thread(UUID)    // post detail + replies
    case profile(UUID)   // user profile
    case bookmarks
    case lists
    case communities
    case settings
}

struct ContentView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showCompose = false

    var body: some View {
        TabView {
            homeTab
                .tabItem { Label("Home", systemImage: "house") }

            TabStack { ExploreView() }
                .tabItem { Label("Explore", systemImage: "magnifyingglass") }

            TabStack { NotificationsView() }
                .tabItem { Label("Alerts", systemImage: "bell") }
                .badge(store.unreadNotificationCount)

            TabStack { MessagesView() }
                .tabItem { Label("Messages", systemImage: "envelope") }
                .badge(store.unreadMessageCount)

            TabStack { ProfileView(userID: store.currentUserID) }
                .tabItem { Label("Profile", systemImage: "person") }
        }
        .sheet(isPresented: $showCompose) {
            ComposeView(mode: .new)
        }
    }

    /// Home carries the floating compose button so it never covers other tabs.
    private var homeTab: some View {
        TabStack {
            HomeView()
                .overlay(alignment: .bottomTrailing) {
                    composeFAB
                }
        }
    }

    private var composeFAB: some View {
        Button {
            showCompose = true
        } label: {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Circle().fill(Color.accentColor))
                .shadow(color: .black.opacity(0.25), radius: 10, y: 4)
        }
        .buttonStyle(PressableStyle(scale: 0.92))
        .padding(20)
        .accessibilityLabel("New Ping")
    }
}

/// Wraps a tab root in a NavigationStack that knows every push destination.
struct TabStack<Root: View>: View {
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
                    case .bookmarks:
                        BookmarksView()
                    case .lists:
                        ListsView()
                    case .communities:
                        CommunitiesView()
                    case .settings:
                        SettingsView()
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
            Circle().fill(user.avatarColor)
            Circle().strokeBorder(.white.opacity(0.2), lineWidth: 1)
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
