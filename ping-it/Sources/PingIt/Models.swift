import SwiftUI

// MARK: - User

enum Verification: Hashable {
    case none
    case blue      // individual premium
    case gold      // organization
    case gray      // government

    var badgeColor: Color? {
        switch self {
        case .none: return nil
        case .blue: return Color(red: 0.11, green: 0.63, blue: 0.95)
        case .gold: return Color(red: 0.83, green: 0.69, blue: 0.22)
        case .gray: return Color(white: 0.55)
        }
    }
}

struct User: Identifiable, Hashable {
    let id: UUID
    var handle: String          // without the @
    var displayName: String
    var bio: String
    var location: String
    var website: String
    var joinDate: Date
    var followerCount: Int
    var followingCount: Int
    var verification: Verification
    var avatarSymbol: String    // SF Symbol used as avatar
    var avatarColor: Color
    var bannerColor: Color
}

// MARK: - Post

struct PollOption: Identifiable, Hashable {
    let id: UUID
    var title: String
    var votes: Int
}

struct Poll: Hashable {
    var options: [PollOption]
    var endDate: Date
    var votedOptionID: UUID?

    var totalVotes: Int { options.reduce(0) { $0 + $1.votes } }
    var isClosed: Bool { endDate < .now }
}

struct Post: Identifiable, Hashable {
    let id: UUID
    var authorID: UUID
    var text: String
    var date: Date
    var likeCount: Int
    var repostCount: Int
    var viewCount: Int
    var replyToID: UUID?
    var quotedPostID: UUID?
    var poll: Poll?
    var communityID: UUID?
    var mediaSymbols: [String] = []   // SF Symbol placeholders standing in for photos
    var isEdited: Bool = false
}

// MARK: - Notifications

struct AppNotification: Identifiable, Hashable {
    enum Kind: Hashable {
        case like, repost, follow, mention, reply

        var symbol: String {
            switch self {
            case .like: return "heart.fill"
            case .repost: return "arrow.2.squarepath"
            case .follow: return "person.fill.badge.plus"
            case .mention: return "at"
            case .reply: return "bubble.left.fill"
            }
        }

        var tint: Color {
            switch self {
            case .like: return .pink
            case .repost: return .green
            case .follow, .mention, .reply: return .accentColor
            }
        }
    }

    let id: UUID
    var kind: Kind
    var actorID: UUID
    var postID: UUID?
    var date: Date
    var isRead: Bool
}

// MARK: - Direct Messages

struct DMMessage: Identifiable, Hashable {
    let id: UUID
    var senderID: UUID
    var text: String
    var date: Date
}

struct Conversation: Identifiable, Hashable {
    let id: UUID
    var participantID: UUID
    var messages: [DMMessage]
    var unreadCount: Int
}

// MARK: - Explore

struct Trend: Identifiable, Hashable {
    let id: UUID
    var category: String
    var topic: String
    var postCount: Int
}

// MARK: - Communities & Lists

struct Community: Identifiable, Hashable {
    let id: UUID
    var name: String
    var symbol: String
    var about: String
    var memberCount: Int
    var isJoined: Bool
}

struct UserList: Identifiable, Hashable {
    let id: UUID
    var name: String
    var about: String
    var memberIDs: [UUID]
    var isPrivate: Bool
}

// MARK: - Formatting helpers

func compactCount(_ n: Int) -> String {
    switch n {
    case ..<1_000: return "\(n)"
    case ..<1_000_000:
        let v = Double(n) / 1_000
        return v < 10 ? String(format: "%.1fK", v) : "\(Int(v))K"
    default:
        let v = Double(n) / 1_000_000
        return v < 10 ? String(format: "%.1fM", v) : "\(Int(v))M"
    }
}

func shortRelativeDate(_ date: Date) -> String {
    let seconds = Int(Date.now.timeIntervalSince(date))
    if seconds < 60 { return "\(max(seconds, 1))s" }
    if seconds < 3_600 { return "\(seconds / 60)m" }
    if seconds < 86_400 { return "\(seconds / 3_600)h" }
    if seconds < 86_400 * 7 { return "\(seconds / 86_400)d" }
    return date.formatted(.dateTime.month(.abbreviated).day())
}

/// Renders #hashtags and @mentions in the accent color.
func styledPostText(_ text: String) -> AttributedString {
    var result = AttributedString()
    guard let regex = try? NSRegularExpression(pattern: "([#@][A-Za-z0-9_]+)") else {
        return AttributedString(text)
    }
    let ns = text as NSString
    var cursor = 0
    for match in regex.matches(in: text, range: NSRange(location: 0, length: ns.length)) {
        if match.range.location > cursor {
            let plain = ns.substring(with: NSRange(location: cursor, length: match.range.location - cursor))
            result += AttributedString(plain)
        }
        var token = AttributedString(ns.substring(with: match.range))
        token.foregroundColor = .accentColor
        result += token
        cursor = match.range.location + match.range.length
    }
    if cursor < ns.length {
        result += AttributedString(ns.substring(from: cursor))
    }
    return result
}
