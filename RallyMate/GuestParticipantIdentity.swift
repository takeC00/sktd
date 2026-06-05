import Foundation

/// レーティング対象外のゲスト参加者（今日だけ参加・旧 Visitor 等）
enum GuestParticipantIdentity {
    static let fixedRating = RatingDefaults.initialRating

    static func isGuest(_ playerId: String) -> Bool {
        VisitorIdentity.isVisitor(playerId)
            || DayParticipantIdentity.isDayParticipant(playerId)
            || EventVisitorIdentity.isEventVisitor(playerId)
    }
}
