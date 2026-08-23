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
                        PostCard(post: post)
                        Divider()
                    }
                    if timeline.isEmpty {
                        ContentUnavailableView("Nothing here yet",
                                               systemImage: "wind",
                                               description: Text("Follow some accounts to fill your Following feed."))
                            .padding(.top, 60)
                    }
                } header: {
                    feedPicker
                }
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
        .background(.background)
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
                store.createPost(text: text)
                quickPingText = ""
            }
            .buttonStyle(.borderedProminent)
            .disabled(quickPingText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.vertical, 12)
    }
}
