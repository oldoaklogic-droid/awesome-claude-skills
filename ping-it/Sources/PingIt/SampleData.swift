import SwiftUI

/// Seed content so PING IT is fully explorable on first launch.
enum SampleData {

    struct Seed {
        var users: [User]
        var posts: [Post]
        var notifications: [AppNotification]
        var conversations: [Conversation]
        var trends: [Trend]
        var communities: [Community]
        var lists: [UserList]
        var currentUserID: UUID
        var likedPostIDs: Set<UUID>
        var bookmarkedPostIDs: Set<UUID>
        var followedUserIDs: Set<UUID>
    }

    static func make() -> Seed {
        let now = Date.now
        func ago(_ hours: Double) -> Date { now.addingTimeInterval(-hours * 3_600) }

        // MARK: Users

        let me = User(id: UUID(), handle: "you", displayName: "You",
                      bio: "Building things and pinging about it. Coffee-powered.",
                      location: "San Francisco, CA", website: "pingit.example",
                      joinDate: ago(24 * 700), followerCount: 1_284, followingCount: 402,
                      verification: .blue, avatarSymbol: "person.crop.circle.fill",
                      avatarColor: .indigo, bannerColor: .indigo)

        let ada = User(id: UUID(), handle: "adacodes", displayName: "Ada Lovelace",
                       bio: "First programmer, still shipping. Opinions are my own algorithms.",
                       location: "London", website: "analyticalengine.dev",
                       joinDate: ago(24 * 2_000), followerCount: 982_000, followingCount: 12,
                       verification: .blue, avatarSymbol: "laptopcomputer",
                       avatarColor: .purple, bannerColor: .purple)

        let kai = User(id: UUID(), handle: "kaitrail", displayName: "Kai Nakamura",
                       bio: "Trail runner 🏔 | Photographer | Chasing golden hour",
                       location: "Boulder, CO", website: "kai.photos",
                       joinDate: ago(24 * 900), followerCount: 45_300, followingCount: 810,
                       verification: .none, avatarSymbol: "mountain.2.fill",
                       avatarColor: .green, bannerColor: .teal)

        let nova = User(id: UUID(), handle: "NovaSpaceHQ", displayName: "Nova Space",
                        bio: "Taking humanity to the stars, one launch at a time. Official account.",
                        location: "Cape Canaveral, FL", website: "novaspace.example",
                        joinDate: ago(24 * 1_500), followerCount: 4_800_000, followingCount: 88,
                        verification: .gold, avatarSymbol: "airplane.departure",
                        avatarColor: .orange, bannerColor: .orange)

        let mira = User(id: UUID(), handle: "mirabakes", displayName: "Mira Chen",
                        bio: "Pastry chef. My croissants have more layers than your codebase.",
                        location: "Paris", website: "mira.recipes",
                        joinDate: ago(24 * 600), followerCount: 120_500, followingCount: 340,
                        verification: .blue, avatarSymbol: "birthday.cake.fill",
                        avatarColor: .pink, bannerColor: .pink)

        let cityDesk = User(id: UUID(), handle: "BayAreaTransit", displayName: "Bay Area Transit",
                            bio: "Official service alerts and updates for Bay Area riders.",
                            location: "Bay Area", website: "transit.example.gov",
                            joinDate: ago(24 * 1_200), followerCount: 310_000, followingCount: 5,
                            verification: .gray, avatarSymbol: "tram.fill",
                            avatarColor: .gray, bannerColor: .blue)

        let leo = User(id: UUID(), handle: "leoplays", displayName: "Leo Martinez",
                       bio: "Indie game dev. Wishlist my roguelike or the crab gets it. 🦀",
                       location: "Austin, TX", website: "crabgame.example",
                       joinDate: ago(24 * 400), followerCount: 8_900, followingCount: 1_200,
                       verification: .none, avatarSymbol: "gamecontroller.fill",
                       avatarColor: .red, bannerColor: .red)

        let sana = User(id: UUID(), handle: "sanawrites", displayName: "Sana Iqbal",
                        bio: "Science journalist. Ask me about tardigrades.",
                        location: "NYC", website: "sana.press",
                        joinDate: ago(24 * 1_100), followerCount: 67_800, followingCount: 990,
                        verification: .blue, avatarSymbol: "text.book.closed.fill",
                        avatarColor: .cyan, bannerColor: .cyan)

        let users = [me, ada, kai, nova, mira, cityDesk, leo, sana]

        // MARK: Communities

        let swiftClub = Community(id: UUID(), name: "Swift Builders",
                                  symbol: "swift", about: "Everything Swift, SwiftUI, and Apple platforms.",
                                  memberCount: 48_200, isJoined: true)
        let trailClub = Community(id: UUID(), name: "Trail Runners",
                                  symbol: "figure.run", about: "Routes, races, and blister remedies.",
                                  memberCount: 12_400, isJoined: false)
        let bakeClub = Community(id: UUID(), name: "Bake Lab",
                                 symbol: "oven.fill", about: "Home bakers and pros sharing what came out of the oven.",
                                 memberCount: 31_900, isJoined: false)
        let communities = [swiftClub, trailClub, bakeClub]

        // MARK: Posts

        var posts: [Post] = []

        let adaPost = Post(id: UUID(), authorID: ada.id,
                           text: "Hot take: the best debugging tool ever invented is explaining your code out loud to someone who isn't listening. #programming",
                           date: ago(2), likeCount: 12_400, repostCount: 2_100, viewCount: 890_000,
                           replyToID: nil, quotedPostID: nil, poll: nil, communityID: nil)
        posts.append(adaPost)

        let novaLaunch = Post(id: UUID(), authorID: nova.id,
                              text: "LIFTOFF! 🚀 Aurora-7 is on its way to orbit carrying 42 research payloads. Watch the booster landing live in 8 minutes. #Aurora7",
                              date: ago(4), likeCount: 88_000, repostCount: 21_000, viewCount: 6_200_000,
                              replyToID: nil, quotedPostID: nil, poll: nil, communityID: nil,
                              mediaSymbols: ["flame.fill", "moon.stars.fill"])
        posts.append(novaLaunch)

        let kaiPhoto = Post(id: UUID(), authorID: kai.id,
                            text: "Sunrise from the summit of Longs Peak this morning. 14,259 ft and worth every step. 🏔",
                            date: ago(7), likeCount: 3_800, repostCount: 410, viewCount: 92_000,
                            replyToID: nil, quotedPostID: nil, poll: nil, communityID: nil,
                            mediaSymbols: ["sun.horizon.fill"])
        posts.append(kaiPhoto)

        let miraPoll = Post(id: UUID(), authorID: mira.id,
                            text: "Settle a bakery argument for me. The superior lamination project is:",
                            date: ago(9),
                            likeCount: 950, repostCount: 120, viewCount: 41_000,
                            replyToID: nil, quotedPostID: nil,
                            poll: Poll(options: [
                                PollOption(id: UUID(), title: "Croissant", votes: 1_420),
                                PollOption(id: UUID(), title: "Kouign-amann", votes: 860),
                                PollOption(id: UUID(), title: "Danish", votes: 445),
                                PollOption(id: UUID(), title: "Puff pastry purist", votes: 300)
                            ], endDate: now.addingTimeInterval(86_400), votedOptionID: nil),
                            communityID: nil)
        posts.append(miraPoll)

        let transitAlert = Post(id: UUID(), authorID: cityDesk.id,
                                text: "SERVICE ALERT: Red line trains are running 10–15 min behind schedule due to earlier signal maintenance. Normal service expected by 6 PM.",
                                date: ago(1), likeCount: 84, repostCount: 260, viewCount: 150_000,
                                replyToID: nil, quotedPostID: nil, poll: nil, communityID: nil)
        posts.append(transitAlert)

        let leoDevlog = Post(id: UUID(), authorID: leo.id,
                             text: "Devlog day 214: the crab can now parry. I repeat: THE CRAB CAN PARRY. 🦀⚔️ #gamedev #indiedev",
                             date: ago(12), likeCount: 2_200, repostCount: 380, viewCount: 64_000,
                             replyToID: nil, quotedPostID: nil, poll: nil, communityID: nil,
                             mediaSymbols: ["gamecontroller.fill"])
        posts.append(leoDevlog)

        let sanaThread = Post(id: UUID(), authorID: sana.id,
                              text: "New piece out today: scientists revived a tardigrade after 30 years frozen, and what they learned could change organ storage forever. A thread 🧵 1/7",
                              date: ago(20), likeCount: 15_600, repostCount: 6_400, viewCount: 1_100_000,
                              replyToID: nil, quotedPostID: nil, poll: nil, communityID: nil)
        posts.append(sanaThread)

        let myPost = Post(id: UUID(), authorID: me.id,
                          text: "Shipped a new build of my side project tonight. It's held together with optimism and three TODO comments, but it WORKS. #buildinpublic",
                          date: ago(15), likeCount: 210, repostCount: 18, viewCount: 9_400,
                          replyToID: nil, quotedPostID: nil, poll: nil, communityID: nil)
        posts.append(myPost)

        let quoteOfNova = Post(id: UUID(), authorID: leo.id,
                               text: "Watching this between compile times. Rocket landings never get old.",
                               date: ago(3), likeCount: 340, repostCount: 22, viewCount: 18_000,
                               replyToID: nil, quotedPostID: novaLaunch.id, poll: nil, communityID: nil)
        posts.append(quoteOfNova)

        let swiftCommunityPost = Post(id: UUID(), authorID: ada.id,
                                      text: "PSA for Swift Builders: @Observable + SwiftUI previews is the fastest iteration loop I've ever had on any platform. Try it before you write another view model protocol.",
                                      date: ago(6), likeCount: 1_900, repostCount: 240, viewCount: 88_000,
                                      replyToID: nil, quotedPostID: nil, poll: nil, communityID: swiftClub.id)
        posts.append(swiftCommunityPost)

        let bakeCommunityPost = Post(id: UUID(), authorID: mira.id,
                                     text: "Bake Lab check-in: today's sourdough hit 92% hydration and survived. Crumb shot below. 🍞",
                                     date: ago(11), likeCount: 720, repostCount: 60, viewCount: 24_000,
                                     replyToID: nil, quotedPostID: nil, poll: nil,
                                     communityID: bakeClub.id, mediaSymbols: ["circle.grid.3x3.fill"])
        posts.append(bakeCommunityPost)

        // Replies
        let replyToAda1 = Post(id: UUID(), authorID: kai.id,
                               text: "@adacodes My rubber duck filed a formal complaint about being replaced by coworkers.",
                               date: ago(1.5), likeCount: 840, repostCount: 31, viewCount: 40_000,
                               replyToID: adaPost.id, quotedPostID: nil, poll: nil, communityID: nil)
        posts.append(replyToAda1)

        let replyToAda2 = Post(id: UUID(), authorID: me.id,
                               text: "@adacodes Can confirm. Solved a race condition mid-sentence yesterday while my friend checked their phone.",
                               date: ago(1), likeCount: 96, repostCount: 4, viewCount: 8_200,
                               replyToID: adaPost.id, quotedPostID: nil, poll: nil, communityID: nil)
        posts.append(replyToAda2)

        let replyToNova = Post(id: UUID(), authorID: sana.id,
                               text: "@NovaSpaceHQ Booster landing confirmed nominal — that's 19 consecutive recoveries for this airframe. Remarkable engineering cadence.",
                               date: ago(3.5), likeCount: 2_600, repostCount: 210, viewCount: 130_000,
                               replyToID: novaLaunch.id, quotedPostID: nil, poll: nil, communityID: nil)
        posts.append(replyToNova)

        let replyToMe = Post(id: UUID(), authorID: leo.id,
                             text: "@you Three TODOs is basically production-ready. Ship it. 🚢",
                             date: ago(14), likeCount: 45, repostCount: 2, viewCount: 3_100,
                             replyToID: myPost.id, quotedPostID: nil, poll: nil, communityID: nil)
        posts.append(replyToMe)

        let sanaThread2 = Post(id: UUID(), authorID: sana.id,
                               text: "2/7 First, the basics: tardigrades survive by entering cryptobiosis — they expel almost all their water and curl into a dehydrated 'tun' state where metabolism drops to 0.01% of normal.",
                               date: ago(19.9), likeCount: 4_900, repostCount: 900, viewCount: 480_000,
                               replyToID: sanaThread.id, quotedPostID: nil, poll: nil, communityID: nil)
        posts.append(sanaThread2)

        // MARK: Notifications

        let notifications = [
            AppNotification(id: UUID(), kind: .like, actorID: ada.id, postID: myPost.id, date: ago(0.5), isRead: false),
            AppNotification(id: UUID(), kind: .reply, actorID: leo.id, postID: replyToMe.id, date: ago(14), isRead: false),
            AppNotification(id: UUID(), kind: .repost, actorID: kai.id, postID: myPost.id, date: ago(5), isRead: false),
            AppNotification(id: UUID(), kind: .follow, actorID: mira.id, postID: nil, date: ago(8), isRead: true),
            AppNotification(id: UUID(), kind: .mention, actorID: leo.id, postID: replyToMe.id, date: ago(14), isRead: true),
            AppNotification(id: UUID(), kind: .like, actorID: sana.id, postID: myPost.id, date: ago(10), isRead: true),
            AppNotification(id: UUID(), kind: .follow, actorID: leo.id, postID: nil, date: ago(30), isRead: true)
        ]

        // MARK: Conversations

        let convoWithLeo = Conversation(id: UUID(), participantID: leo.id, messages: [
            DMMessage(id: UUID(), senderID: leo.id, text: "Yo, did you see the crab parry clip??", date: ago(26)),
            DMMessage(id: UUID(), senderID: me.id, text: "Saw it. Instant wishlist.", date: ago(25.5)),
            DMMessage(id: UUID(), senderID: leo.id, text: "Legend. Beta build goes out Friday if you want in.", date: ago(0.4))
        ], unreadCount: 1)

        let convoWithMira = Conversation(id: UUID(), participantID: mira.id, messages: [
            DMMessage(id: UUID(), senderID: me.id, text: "That poll is going to start a war, you know that right", date: ago(8)),
            DMMessage(id: UUID(), senderID: mira.id, text: "Chaos is the secret ingredient 😌", date: ago(7.8))
        ], unreadCount: 0)

        let convoWithKai = Conversation(id: UUID(), participantID: kai.id, messages: [
            DMMessage(id: UUID(), senderID: kai.id, text: "Longs Peak in October — you in? Training plan attached (it's just 'run uphill a lot').", date: ago(50)),
            DMMessage(id: UUID(), senderID: me.id, text: "Ha. Let me check my calendar and my cardiovascular system.", date: ago(49))
        ], unreadCount: 0)

        let conversations = [convoWithLeo, convoWithMira, convoWithKai]

        // MARK: Trends

        let trends = [
            Trend(id: UUID(), category: "Science · Trending", topic: "#Aurora7", postCount: 182_000),
            Trend(id: UUID(), category: "Technology · Trending", topic: "SwiftUI", postCount: 54_300),
            Trend(id: UUID(), category: "Trending in United States", topic: "Tardigrades", postCount: 21_700),
            Trend(id: UUID(), category: "Gaming · Trending", topic: "#indiedev", postCount: 33_100),
            Trend(id: UUID(), category: "Food · Trending", topic: "Croissant Debate", postCount: 9_800),
            Trend(id: UUID(), category: "Sports · Trending", topic: "Longs Peak", postCount: 4_100),
            Trend(id: UUID(), category: "Technology · Trending", topic: "#buildinpublic", postCount: 12_600)
        ]

        // MARK: Lists

        let lists = [
            UserList(id: UUID(), name: "Tech Voices", about: "People who make me smarter about software.",
                     memberIDs: [ada.id, leo.id, sana.id], isPrivate: false),
            UserList(id: UUID(), name: "Outdoors", about: "Trails, peaks, and people who climb them.",
                     memberIDs: [kai.id], isPrivate: false),
            UserList(id: UUID(), name: "Doomscroll Antidote", about: "Only good posts allowed.",
                     memberIDs: [mira.id, kai.id, leo.id], isPrivate: true)
        ]

        return Seed(users: users,
                    posts: posts,
                    notifications: notifications,
                    conversations: conversations,
                    trends: trends,
                    communities: communities,
                    lists: lists,
                    currentUserID: me.id,
                    likedPostIDs: [kaiPhoto.id, sanaThread.id],
                    bookmarkedPostIDs: [sanaThread.id, swiftCommunityPost.id],
                    followedUserIDs: [ada.id, kai.id, mira.id, leo.id, sana.id])
    }
}
