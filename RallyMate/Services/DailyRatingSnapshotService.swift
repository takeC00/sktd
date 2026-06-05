import Foundation
import FirebaseFirestore

enum DailyRatingSnapshotError: LocalizedError {
    case noCircle
    case noMatchesToday

    var errorDescription: String? {
        switch self {
        case .noCircle: "サークルが選択されていません"
        case .noMatchesToday: "本日の試合結果がありません。試合を登録してから QR を生成してください。"
        }
    }
}

@MainActor
final class DailyRatingSnapshotService {
    static let shared = DailyRatingSnapshotService()

    private var db: Firestore { Firestore.firestore() }

    private init() {}

    func buildSnapshot(
        store: AppStore,
        circleId: String,
        circleName: String,
        members: [CircleMembership],
        dateKey: String = MateAppConfig.todayDateKeyInJST()
    ) throws -> DailyRatingSnapshot {
        let todayMatches = store.matches(on: dateKey, circleId: circleId)
        guard !todayMatches.isEmpty else {
            throw DailyRatingSnapshotError.noMatchesToday
        }

        var participantIds = Set<String>()
        for match in todayMatches {
            for participantId in match.teamAPlayers + match.teamBPlayers {
                if GuestParticipantIdentity.isGuest(participantId) {
                    continue
                }
                participantIds.insert(participantId)
            }
        }

        var entries: [DailyRatingEntry] = []
        for participantId in participantIds {
            guard let member = store.membership(for: participantId, in: members) else {
                continue
            }

            let dayChange = store.totalRatingChange(
                for: participantId,
                on: dateKey,
                circleId: circleId
            )
            let ratingAfter = member.rating
            let ratingBefore = ratingAfter - dayChange

            entries.append(
                DailyRatingEntry(
                    participantId: participantId,
                    name: member.userName,
                    ratingBefore: ratingBefore,
                    ratingChange: dayChange,
                    ratingAfter: ratingAfter
                )
            )
        }

        entries.sort { lhs, rhs in
            if lhs.ratingChange != rhs.ratingChange {
                return lhs.ratingChange > rhs.ratingChange
            }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }

        return DailyRatingSnapshot(
            documentId: MateAppConfig.snapshotDocumentId(circleId: circleId, dateKey: dateKey),
            circleId: circleId,
            circleName: circleName,
            dateKey: dateKey,
            publishedAt: .now,
            entries: entries
        )
    }

    func publish(_ snapshot: DailyRatingSnapshot) async throws {
        let entriesData: [[String: Any]] = snapshot.entries.map { entry in
            [
                "participantId": entry.participantId,
                "name": entry.name,
                "ratingBefore": entry.ratingBefore,
                "ratingChange": entry.ratingChange,
                "ratingAfter": entry.ratingAfter,
            ]
        }

        try await db.collection("ratingSnapshots")
            .document(snapshot.documentId)
            .setData([
                "circleId": snapshot.circleId,
                "circleName": snapshot.circleName,
                "dateKey": snapshot.dateKey,
                "publishedAt": Timestamp(date: snapshot.publishedAt),
                "entries": entriesData,
            ])
    }

    func publishSnapshot(
        store: AppStore,
        circleId: String,
        circleName: String,
        members: [CircleMembership]
    ) async throws -> DailyRatingSnapshot {
        let snapshot = try buildSnapshot(
            store: store,
            circleId: circleId,
            circleName: circleName,
            members: members
        )
        try await publish(snapshot)
        return snapshot
    }
}
