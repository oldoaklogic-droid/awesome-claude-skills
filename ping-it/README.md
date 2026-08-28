# PING IT 📡

A native iOS app (iPhone-first, iPad compatible) that replicates the functionality of X.com (formerly Twitter), built entirely with **Swift** and **SwiftUI**. Everything runs locally against rich sample data, so the whole app is interactive out of the box — no server, no accounts, no network.

> PING IT is an original demo app. It reproduces the *functionality* of X.com with its own name, branding, and fictional sample content.

## Requirements

- Xcode 15+ on a Mac (free from the App Store)
- iOS 17 simulator or device

## Running the app (iPhone)

```sh
open Package.swift
```

Xcode opens the package as an iOS app. In the toolbar, pick an **iPhone simulator**
(e.g. iPhone 15 Pro) as the run destination, then press **Run** (⌘R). The app
builds and launches in the simulator. To run on a real iPhone, select your device
and set your Apple ID under Signing.

## Feature parity with X.com

The feature set was researched against X.com as of 2026 and mapped onto native iOS equivalents:

| X.com feature | PING IT equivalent |
| --- | --- |
| Home timeline with **For You** (ranked) and **Following** (chronological) tabs | `HomeView` — For You ranks by an engagement/recency score; Following shows accounts you follow, newest first |
| Posts (tweets) with hashtags & mentions | "Pings" — `#hashtags` and `@mentions` are highlighted in the accent color |
| Reply, repost, quote post | Reply composer in threads, repost menu with **Repost** / **Quote** options |
| Like, bookmark, share, view counts | Full action bar on every post; share copies a `pingit://` deep link |
| Threads / post detail pages | `ThreadView` with parent post, stats row (views/reposts/likes/replies), and inline reply box |
| Polls (up to 4 choices) | Create polls in the composer, vote once, animated result bars, vote totals & end time |
| Media attachments | SF-Symbol media placeholders on posts |
| Profiles (banner, bio, location, website, join date, follower counts) | `ProfileView` with Pings / Replies / Likes tabs and profile editing |
| Follow / unfollow, who to follow | Follow buttons everywhere; suggestions in Explore |
| Verification badges (blue / gold organization / gray government) | `Verification` tiers rendered as colored seals |
| Explore: trending topics + search | `ExploreView` — trends for you (click to search), live search over people and posts |
| Notifications (All / Mentions / Verified) with unread badge | `NotificationsView` with filter tabs; sidebar badge clears on visit |
| Direct Messages | `MessagesView` — conversation list, chat bubbles, unread dots, and a playful auto-reply |
| Bookmarks page | `BookmarksView` |
| Lists (public & private) | `ListsView` with expandable member rosters |
| Communities | `CommunitiesView` — join/leave, member counts, expandable community posts |
| X Premium (edit posts, 25,000-char limit, blue check) | Premium toggle in Settings: unlocks **Edit ping**, raises the composer limit from 280 to 25,000, and grants your badge |
| Edit / delete your posts | Post `…` menu (edit requires Premium, mirroring X) |
| Character counter ring | Live progress ring in the composer, warns near the limit |
| Dark mode | System / Light / Dark appearance picker in Settings |

Deliberately out of scope (they need real infrastructure): Spaces (live audio), video playback, X Money payments, Grok AI, and ads.

## Architecture

```
ping-it/
├── Package.swift               # iOS application package (open in Xcode), iOS 17+
└── Sources/PingIt/
    ├── PingItApp.swift         # @main entry + appearance handling
    ├── Theme.swift             # Motion tokens, press feedback, heart burst, empty states
    ├── Models.swift            # User, Post, Poll, Notification, DM, Trend, Community, List
    ├── AppStore.swift          # @MainActor ObservableObject: feeds, actions, search
    ├── SampleData.swift        # Seed users, posts, threads, DMs, trends, communities
    ├── ContentView.swift       # Tab bar shell, compose FAB, shared components
    ├── HomeView.swift          # For You / Following timeline + quick composer
    ├── PostViews.swift         # Post cards, polls, quotes, action bar, thread view
    ├── ComposeView.swift       # New / reply / quote / edit composer with polls
    ├── ExploreView.swift       # Trends, search, who to follow
    ├── NotificationsView.swift # Filtered notification feed
    ├── MessagesView.swift      # Conversation list + chat screens
    ├── ProfileView.swift       # Profiles + edit profile sheet
    └── SidebarExtras.swift     # Bookmarks, Lists, Communities, Settings (pushed from Profile)
```

State lives in a single `@MainActor` `AppStore` (`ObservableObject`) injected via `environmentObject`, with value-type models and unidirectional actions — every interaction (like, repost, vote, follow, DM, edit) mutates the store and the UI updates reactively.
