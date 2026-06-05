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

struct CircleVisitor: Identifiable, Equatable {
    let playerId: String
    let rosterDocumentId: String
    let name: String

    var id: String { playerId }
}
