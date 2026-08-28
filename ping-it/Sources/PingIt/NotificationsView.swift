import SwiftUI

struct NotificationsView: View {
    enum Filter: String, CaseIterable, Identifiable {
        case all = "All"
        case mentions = "Mentions"
        case verified = "Verified"
        var id: String { rawValue }
    }

    @EnvironmentObject private var store: AppStore
    @State private var filter: Filter = .all

    private var filtered: [AppNotification] {
        let sorted = store.notifications.sorted { $0.date > $1.date }
        switch filter {
        case .all:
            return sorted
        case .mentions:
            return sorted.filter { $0.kind == .mention || $0.kind == .reply }
        case .verified:
            return sorted.filter { store.user($0.actorID).verification != .none }
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                Picker("Filter", selection: $filter) {
                    ForEach(Filter.allCases) { f in
                        Text(f.rawValue).tag(f)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .padding(.vertical, 8)

                ForEach(filtered) { notification in
                    NotificationRow(notification: notification)
                    Divider()
                }

                if filtered.isEmpty {
                    EmptyStateView(symbol: "bell.badge",
                                   title: "All caught up",
                                   message: "When someone likes, replies, or follows, it lands here.")
                }
            }
            .padding(.horizontal, 16)
        }
        .navigationTitle("Notifications")
        .onAppear { store.markNotificationsRead() }
    }
}

private struct NotificationRow: View {
    @EnvironmentObject private var store: AppStore
    let notification: AppNotification

    private var actor: User { store.user(notification.actorID) }

    private var message: String {
        switch notification.kind {
        case .like: return "liked your ping"
        case .repost: return "reposted your ping"
        case .follow: return "followed you"
        case .mention: return "mentioned you"
        case .reply: return "replied to your ping"
        }
    }

    var body: some View {
        let row = HStack(alignment: .top, spacing: 12) {
            Image(systemName: notification.kind.symbol)
                .font(.title3)
                .foregroundStyle(notification.kind.tint)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    AvatarView(user: actor, size: 28)
                    Text("\(actor.displayName) ").bold() + Text(message).foregroundStyle(.secondary)
                    Spacer()
                    Text(shortRelativeDate(notification.date))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let postID = notification.postID, let post = store.post(postID) {
                    Text(post.text)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .padding(.leading, 34)
                }
            }
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())

        if let postID = notification.postID, store.post(postID) != nil {
            NavigationLink(value: Route.thread(postID)) { row.hoverHighlight() }
                .buttonStyle(PressableStyle(scale: 0.98))
        } else {
            NavigationLink(value: Route.profile(actor.id)) { row.hoverHighlight() }
                .buttonStyle(PressableStyle(scale: 0.98))
        }
    }
}
