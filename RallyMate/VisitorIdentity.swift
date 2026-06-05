import Foundation

/// RallyMatch の `circleRoster`（Visitor）を Mate 試合に参加させるための ID 形式
enum VisitorIdentity {
    static let prefix = "visitor:"
    static let displayName = "Visitor"
    static let fixedRating = RatingDefaults.initialRating

    static func playerId(rosterDocumentId: String) -> String {
        prefix + rosterDocumentId
    }

    static func isVisitor(_ playerId: String) -> Bool {
        playerId.hasPrefix(prefix)
    }

    static func rosterDocumentId(from playerId: String) -> String? {
        guard isVisitor(playerId) else { return nil }
        return String(playerId.dropFirst(prefix.count))
    }
}

struct CircleGuestParticipant: Identifiable, Equatable {
    let matchParticipantId: String
    let name: String
    /// 今日だけ参加の経験者 / 初心者（`circleDayParticipants.level`）
    let level: String?

    var id: String { matchParticipantId }

    init(matchParticipantId: String, name: String, level: String? = nil) {
        self.matchParticipantId = matchParticipantId
        self.name = name
        self.level = level
    }
}

/// 後方互換
typealias CircleVisitor = CircleGuestParticipant

extension CircleGuestParticipant {
    var playerId: String { matchParticipantId }
}
