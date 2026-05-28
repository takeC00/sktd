import Foundation
import FirebaseFirestore

final class MatchFirestoreService {

    static let shared = MatchFirestoreService()

    private let db = Firestore.firestore()

    private init() {}

    func listenMatches(
        circleId: String,
        onChange: @escaping (Result<[MatchResult], Error>) -> Void
    ) -> ListenerRegistration {
        db.collection("matches")
            .whereField("circleId", isEqualTo: circleId)
            .order(by: "date", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    onChange(.failure(error))
                    return
                }

                let matches = snapshot?.documents.compactMap {
                    Self.match(from: $0)
                } ?? []
                onChange(.success(matches))
            }
    }

    func fetchMatches(
        circleId: String,
        completion: @escaping (Result<[MatchResult], Error>) -> Void
    ) {
        db.collection("matches")
            .whereField("circleId", isEqualTo: circleId)
            .order(by: "date", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                let matches = snapshot?.documents.compactMap {
                    Self.match(from: $0)
                } ?? []

                completion(.success(matches))
            }
    }

    func register(
        match: MatchResult,
        memberRatings: [String: Int],
        completion: @escaping (Result<MatchResult, Error>) -> Void
    ) {
        let ref = db.collection("matches").document()
        var saved = match
        saved.id = ref.documentID

        let batch = db.batch()
        batch.setData(Self.data(from: saved), forDocument: ref)

        for (docId, rating) in memberRatings {
            batch.updateData(
                ["rating": rating],
                forDocument: db.collection("circleMembers").document(docId)
            )
        }

        batch.commit { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            completion(.success(saved))
        }
    }

    func update(
        match: MatchResult,
        memberRatings: [String: Int],
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let batch = db.batch()
        batch.setData(
            Self.data(from: match),
            forDocument: db.collection("matches").document(match.id)
        )

        for (docId, rating) in memberRatings {
            batch.updateData(
                ["rating": rating],
                forDocument: db.collection("circleMembers").document(docId)
            )
        }

        batch.commit { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            completion(.success(()))
        }
    }

    private static func data(from match: MatchResult) -> [String: Any] {
        [
            "circleId": match.circleId,
            "date": Timestamp(date: match.date),
            "matchType": match.matchType.rawValue,
            "teamAPlayers": match.teamAPlayers,
            "teamBPlayers": match.teamBPlayers,
            "setScores": match.setScores.map {
                [
                    "teamAScore": $0.teamAScore,
                    "teamBScore": $0.teamBScore
                ]
            },
            "winner": match.winner,
            "ratingDiff": match.ratingDiff
        ]
    }

    private static func match(from document: QueryDocumentSnapshot) -> MatchResult? {
        let data = document.data()

        guard
            let circleId = data["circleId"] as? String,
            let date = data["date"] as? Timestamp,
            let matchTypeRaw = data["matchType"] as? String,
            let matchType = MatchType(rawValue: matchTypeRaw),
            let teamAPlayers = data["teamAPlayers"] as? [String],
            let teamBPlayers = data["teamBPlayers"] as? [String],
            let winner = data["winner"] as? String,
            let ratingDiff = data["ratingDiff"] as? Int
        else {
            return nil
        }

        let setScoresData = data["setScores"] as? [[String: Any]] ?? []
        let setScores = setScoresData.map { item -> SetScore in
            SetScore(
                teamAScore: item["teamAScore"] as? String ?? "",
                teamBScore: item["teamBScore"] as? String ?? ""
            )
        }

        return MatchResult(
            id: document.documentID,
            circleId: circleId,
            date: date.dateValue(),
            matchType: matchType,
            teamAPlayers: teamAPlayers,
            teamBPlayers: teamBPlayers,
            setScores: setScores,
            winner: winner,
            ratingDiff: ratingDiff
        )
    }
}
