import Foundation

// Firestore: circleMembers コレクション用
struct CircleMembership: Identifiable {
    let id: String
    let circleId: String
    let userId: String?
    let userName: String
    var rating: Int
    var role: String
    let memberType: MemberType
    let level: String?
    let notes: String?
    let isActive: Bool
    let joinedAt: Date

    var isRegistered: Bool { memberType == .registered }
    var isManual: Bool { memberType == .manual }

    /// 試合データに保存する参加者 ID
    var matchParticipantId: String {
        switch memberType {
        case .registered:
            return userId ?? id
        case .manual:
            return ManualMemberIdentity.playerId(circleMemberDocumentId: id)
        }
    }
}

enum MatchType: String, CaseIterable {
    case singles = "シングルス"
    case doubles = "ダブルス"
}

struct SetScore: Identifiable {
    let id = UUID()
    var teamAScore: String
    var teamBScore: String
}

struct MatchResult: Identifiable {
    var id: String
    let circleId: String
    let date: Date
    let matchType: MatchType
    let teamAPlayers: [String]
    let teamBPlayers: [String]
    let setScores: [SetScore]
    let winner: String
    let ratingDiff: Int
    /// 試合登録時に適用したプレイヤーごとのレート変動（participantId → 変動値）
    var ratingChangesByUserId: [String: Int]
}

enum RatingDefaults {
    static let initialRating = 1500
}

func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ja_JP")
    formatter.dateFormat = "yyyy/MM/dd HH:mm"
    return formatter.string(from: date)
}

func formatOnlyDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ja_JP")
    formatter.dateFormat = "yyyy/MM/dd"
    return formatter.string(from: date)
}
