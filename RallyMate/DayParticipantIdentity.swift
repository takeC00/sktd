import Foundation

/// RallyMatch の「今日だけ参加」（Firestore `circleDayParticipants`）
enum DayParticipantIdentity {
    static let prefix = "day:"
    static let fixedRating = RatingDefaults.initialRating

    static func playerId(circleId: String, participantId: UUID) -> String {
        prefix + circleId + "_" + participantId.uuidString.lowercased()
    }

    static func isDayParticipant(_ playerId: String) -> Bool {
        playerId.hasPrefix(prefix)
    }

    static func parse(playerId: String) -> (circleId: String, participantId: UUID)? {
        guard isDayParticipant(playerId) else { return nil }
        let rest = String(playerId.dropFirst(prefix.count))
        guard let underscore = rest.lastIndex(of: "_") else { return nil }
        let circleId = String(rest[..<underscore])
        let uuidString = String(rest[rest.index(after: underscore)...])
        guard let uuid = UUID(uuidString: uuidString) else { return nil }
        return (circleId, uuid)
    }
}
