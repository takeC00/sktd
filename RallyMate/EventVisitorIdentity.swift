import Foundation

/// RallyHub の `eventVisitors`
enum EventVisitorIdentity {
    static let prefix = "eventVisitor:"
    static let fixedRating = RatingDefaults.initialRating

    static func playerId(visitorId: String) -> String {
        prefix + visitorId
    }

    static func isEventVisitor(_ playerId: String) -> Bool {
        playerId.hasPrefix(prefix)
    }

    static func visitorId(from playerId: String) -> String? {
        guard isEventVisitor(playerId) else { return nil }
        return String(playerId.dropFirst(prefix.count))
    }
}
