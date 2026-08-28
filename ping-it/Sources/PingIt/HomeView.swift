import SwiftUI

struct HomeView: View {
    enum Feed: String, CaseIterable, Identifiable {
        case forYou = "For You"
        case following = "Following"
        var id: String { rawValue }
    }

    @EnvironmentObject private var store: AppStore
    @State private var feed: Feed = .forYou
    @State private var quickPingText = ""

    private var timeline: [Post] {
        feed == .forYou ? store.forYouFeed : store.followingFeed
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0, pinnedViews: .sectionHeaders) {
                Section {
                    quickComposer
                    Divider()
                    ForEach(timeline) { post in
                        Group {
                            PostCard(post: post)
                            Divider()
                        }
                        .scrollTransition(.animated(.easeOut(duration: 0.25))) { content, phase in
                            content
                                .opacity(phase.isIdentity ? 1 : 0.3)
                                .offset(y: phase.isIdentity ? 0 : 12)
                        }
                    }
                    if timeline.isEmpty {
                        EmptyStateView(symbol: "wind",
                                       title: "Your feed is waiting",
                                       message: "Follow a few voices you trust and this space fills with conversation.")
                    }
                } header: {
                    feedPicker
                }
                .animation(Motion.standard, value: feed)
            }
            .padding(.horizontal, 16)
        }
        .navigationTitle("Home")
    }

    private var feedPicker: some View {
        Picker("Feed", selection: $feed) {
            ForEach(Feed.allCases) { feed in
                Text(feed.rawValue).tag(feed)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(.ultraThinMaterial)
    }

    private var quickComposer: some View {
        HStack(alignment: .top, spacing: 10) {
            AvatarView(user: store.currentUser, size: 36)
            TextField("What is happening?!", text: $quickPingText, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.title3)
                .lineLimit(1...6)
            Button("Ping") {
                let text = quickPingText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !text.isEmpty, text.count <= store.characterLimit else { return }
                withAnimation(Motion.standard) {
                    store.createPost(text: text)
                }
                quickPingText = ""
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(quickPingText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(quickPingText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
            .animation(Motion.fade, value: quickPingText.isEmpty)
        }
        .padding(.vertical, 12)
    }
}
