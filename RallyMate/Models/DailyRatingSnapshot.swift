import Foundation

struct DailyRatingEntry: Identifiable, Hashable, Sendable {
    let participantId: String
    let name: String
    let ratingBefore: Int
    let ratingChange: Int
    let ratingAfter: Int

    var id: String { participantId }
}

struct DailyRatingSnapshot: Identifiable, Hashable, Sendable {
    let documentId: String
    let circleId: String
    let circleName: String
    let dateKey: String
    let publishedAt: Date
    let entries: [DailyRatingEntry]

    var id: String { documentId }
}
