import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore

class AppStore: ObservableObject {

    @Published var matchResults: [MatchResult] = []
    @Published var isLoadingMatches = false
    @Published var lastErrorMessage: String?

    private let authManager = FirebaseAuthManager.shared
    private let matchService = MatchFirestoreService.shared
    private var matchesListener: ListenerRegistration?
    private var listeningCircleId: String?

    var currentUserId: String {
        authManager.currentUser?.uid ?? ""
    }

    var currentUserName: String {
        authManager.currentUserName
    }

    var currentCircleId: String {
        authManager.currentCircleId ?? ""
    }

    func ratingInCurrentCircle(userId: String) -> Int {
        authManager.currentCircleMembers
            .first { $0.userId == userId }?
            .rating ?? RatingDefaults.initialRating
    }

    func startListeningMatches() {
        guard let circleId = authManager.currentCircleId else {
            return
        }

        if listeningCircleId == circleId, matchesListener != nil {
            return
        }

        matchesListener?.remove()
        listeningCircleId = circleId
        isLoadingMatches = true

        matchesListener = matchService.listenMatches(circleId: circleId) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoadingMatches = false
                switch result {
                case .success(let matches):
                    self.matchResults = matches
                    self.lastErrorMessage = nil
                case .failure(let error):
                    self.lastErrorMessage = error.localizedDescription
                    print(error.localizedDescription)
                }
            }
        }
    }

    func stopListeningMatches() {
        matchesListener?.remove()
        matchesListener = nil
        listeningCircleId = nil
    }

    func registerMatch(
        _ result: MatchResult,
        completion: ((Error?) -> Void)? = nil
    ) {
        guard let circleId = authManager.currentCircleId else {
            completion?(
                NSError(
                    domain: "",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "サークルが選択されていません"]
                )
            )
            return
        }

        let match = MatchResult(
            id: result.id,
            circleId: circleId,
            date: result.date,
            matchType: result.matchType,
            teamAPlayers: result.teamAPlayers,
            teamBPlayers: result.teamBPlayers,
            setScores: result.setScores,
            winner: result.winner,
            ratingDiff: result.ratingDiff
        )

        let memberRatings = ratingsAfterApplying(match: match, sign: 1)

        matchService.register(match: match, memberRatings: memberRatings) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }

                switch result {
                case .success(let saved):
                    self.matchResults.insert(saved, at: 0)
                    self.authManager.fetchCurrentCircleMembers()
                    completion?(nil)
                case .failure(let error):
                    self.lastErrorMessage = error.localizedDescription
                    completion?(error)
                }
            }
        }
    }

    func updateMatch(
        _ updated: MatchResult,
        completion: ((Error?) -> Void)? = nil
    ) {
        guard
            let oldMatch = matchResults.first(where: { $0.id == updated.id })
        else {
            completion?(
                NSError(
                    domain: "",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "試合が見つかりません"]
                )
            )
            return
        }

        var ratings = currentMemberRatings()
        applyMatchImpact(&ratings, match: oldMatch, sign: -1)
        applyMatchImpact(&ratings, match: updated, sign: 1)

        matchService.update(match: updated, memberRatings: ratings) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }

                switch result {
                case .success:
                    if let index = self.matchResults.firstIndex(where: { $0.id == updated.id }) {
                        self.matchResults[index] = updated
                    }
                    self.authManager.fetchCurrentCircleMembers()
                    completion?(nil)
                case .failure(let error):
                    self.lastErrorMessage = error.localizedDescription
                    completion?(error)
                }
            }
        }
    }

    func averageRating(for playerNames: [String]) -> Int {
        let ratings = playerNames.compactMap { userId -> Int? in
            authManager.currentCircleMembers
                .first { $0.userId == userId }?
                .rating
        }

        if ratings.isEmpty {
            return RatingDefaults.initialRating
        }

        return ratings.reduce(0, +) / ratings.count
    }

    func calculateEloDiff(
        playerRating: Int,
        opponentRating: Int,
        didWin: Bool,
        rule: RatingRule = .normal
    ) -> Int {

        let expectedScore =
            1.0 /
            (1.0 + pow(
                10.0,
                Double(opponentRating - playerRating) / 400.0
            ))

        let actualScore = didWin ? 1.0 : 0.0

        var rounded = Int(
            (rule.kFactor * (actualScore - expectedScore)).rounded()
        )

        if didWin {
            rounded = max(rounded, rule.minimumChange)
            rounded = min(rounded, rule.maximumChange)
        } else {
            rounded = min(rounded, -rule.minimumChange)
            rounded = max(rounded, -rule.maximumChange)
        }

        return rounded
    }

    func lossProtectionMultiplier(
        rating: Int,
        rule: RatingRule = .normal
    ) -> Double {

        switch rating {
        case ..<rule.eRankBorder:
            return rule.fRankProtectionMultiplier

        case rule.eRankBorder..<rule.dRankBorder:
            return rule.eRankProtectionMultiplier

        default:
            return 1.0
        }
    }

    // MARK: - Rating helpers

    private func currentMemberRatings() -> [String: Int] {
        Dictionary(
            uniqueKeysWithValues: authManager.currentCircleMembers.map {
                ($0.id, $0.rating)
            }
        )
    }

    private func ratingsAfterApplying(
        match: MatchResult,
        sign: Int
    ) -> [String: Int] {
        var ratings = currentMemberRatings()
        applyMatchImpact(&ratings, match: match, sign: sign)
        return ratings
    }

    private func applyMatchImpact(
        _ ratings: inout [String: Int],
        match: MatchResult,
        sign: Int,
        rule: RatingRule = .normal
    ) {
        let members = authManager.currentCircleMembers
        let allPlayers = match.teamAPlayers + match.teamBPlayers

        for userId in allPlayers {
            guard
                let member = members.first(where: { $0.userId == userId }),
                let rawDiff = playerRatingDelta(match: match, playerId: userId)
            else {
                continue
            }

            let diff = rawDiff * sign
            let current = ratings[member.id] ?? member.rating
            var adjustedDiff = diff

            if diff < 0 {
                adjustedDiff = Int(
                    Double(diff) * lossProtectionMultiplier(
                        rating: current,
                        rule: rule
                    )
                )
            }

            ratings[member.id] = max(current + adjustedDiff, rule.minimumRating)
        }
    }

    private func playerRatingDelta(
        match: MatchResult,
        playerId: String
    ) -> Int? {
        if match.teamAPlayers.contains(playerId) {
            return match.winner == "A"
                ? match.ratingDiff
                : -match.ratingDiff
        }

        if match.teamBPlayers.contains(playerId) {
            return match.winner == "B"
                ? match.ratingDiff
                : -match.ratingDiff
        }

        return nil
    }

    func memberName(for userId: String) -> String {
        authManager.currentCircleMembers.first(where: { $0.userId == userId })?.userName ?? ""
    }
}
