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

    /// 選択中サークルの試合のみ（他サークルのデータ混入を防ぐ）
    var matchesForCurrentCircle: [MatchResult] {
        guard let circleId = authManager.currentCircleId, !circleId.isEmpty else {
            return []
        }
        return matchResults.filter { $0.circleId == circleId }
    }

    func isMatchInCurrentCircle(_ match: MatchResult) -> Bool {
        guard let circleId = authManager.currentCircleId else { return false }
        return match.circleId == circleId
    }

    /// 選択中サークルでユーザーが参加した試合（新しい順）
    func participantMatchesForCurrentCircle(userId: String, limit: Int? = nil) -> [MatchResult] {
        let matches = matchesForCurrentCircle
            .filter { isUserParticipant(in: $0, userId: userId) }
            .sorted { $0.date > $1.date }
        guard let limit else { return matches }
        return Array(matches.prefix(limit))
    }

    /// レーティング推移グラフ用（選択中サークルの直近試合のみ）
    func ratingHistory(for userId: String, limit: Int = 20) -> [Int] {
        let myRating = ratingInCurrentCircle(userId: userId)
        let chronological = participantMatchesForCurrentCircle(userId: userId)
            .sorted { $0.date < $1.date }
        let recentMatches = Array(chronological.suffix(limit))

        let signedDiffs = recentMatches.compactMap {
            userRatingChange(for: $0, userId: userId)
        }
        let totalDiff = signedDiffs.reduce(0, +)

        var values = [myRating - totalDiff]
        for diff in signedDiffs {
            values.append(values.last! + diff)
        }
        return values
    }

    func ratingInCurrentCircle(userId: String) -> Int {
        guard let circleId = authManager.currentCircleId else {
            return RatingDefaults.initialRating
        }
        return ratingInCircle(circleId: circleId, userId: userId)
    }

    func startListeningMatches() {
        guard let circleId = authManager.currentCircleId else {
            matchResults = []
            return
        }

        if listeningCircleId == circleId, matchesListener != nil {
            return
        }

        matchesListener?.remove()
        listeningCircleId = circleId
        matchResults = []
        isLoadingMatches = true

        matchesListener = matchService.listenMatches(circleId: circleId) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                guard self.listeningCircleId == circleId else { return }
                self.isLoadingMatches = false
                switch result {
                case .success(let matches):
                    self.matchResults = matches.filter { $0.circleId == circleId }
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
        matchResults = []
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
            ratingDiff: result.ratingDiff,
            ratingChangesByUserId: [:]
        )

        guard match.circleId == circleId else {
            completion?(
                NSError(
                    domain: "",
                    code: -2,
                    userInfo: [NSLocalizedDescriptionKey: "選択中のサークルと一致しません"]
                )
            )
            return
        }

        let applied = ratingsAfterApplying(match: match, sign: 1)
        var savedMatch = match
        savedMatch.ratingChangesByUserId = applied.changesByUserId

        matchService.register(match: savedMatch, memberRatings: applied.memberRatings) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }

                switch result {
                case .success(let saved):
                    if saved.circleId == circleId {
                        self.matchResults.removeAll { $0.id == saved.id }
                        self.matchResults.insert(saved, at: 0)
                        self.matchResults = self.matchResults.filter { $0.circleId == circleId }
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

    func updateMatch(
        _ updated: MatchResult,
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

        guard updated.circleId == circleId else {
            completion?(
                NSError(
                    domain: "",
                    code: -2,
                    userInfo: [NSLocalizedDescriptionKey: "選択中のサークルの試合のみ編集できます"]
                )
            )
            return
        }

        guard
            let oldMatch = matchesForCurrentCircle.first(where: { $0.id == updated.id })
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

        var ratings = currentMemberRatings(for: updated.circleId)
        var discardedChanges: [String: Int] = [:]
        applyMatchImpact(
            &ratings,
            match: oldMatch,
            sign: -1,
            circleId: updated.circleId,
            changesByUserId: &discardedChanges
        )
        applyMatchImpact(
            &ratings,
            match: updated,
            sign: 1,
            circleId: updated.circleId,
            changesByUserId: &discardedChanges
        )

        let changesByUserId = ratingChangesFromApplying(
            match: updated,
            circleId: updated.circleId
        )
        var matchToSave = updated
        matchToSave.ratingChangesByUserId = changesByUserId

        matchService.update(match: matchToSave, memberRatings: ratings) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }

                switch result {
                case .success:
                    if updated.circleId == self.authManager.currentCircleId,
                       let index = self.matchResults.firstIndex(where: { $0.id == updated.id }) {
                        self.matchResults[index] = matchToSave
                        self.matchResults = self.matchResults.filter {
                            $0.circleId == self.authManager.currentCircleId
                        }
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

    func averageRating(for playerIds: [String]) -> Int {
        guard let circleId = authManager.currentCircleId else {
            return RatingDefaults.initialRating
        }

        let ratings = playerIds.map { ratingForParticipant($0, circleId: circleId) }
        if ratings.isEmpty {
            return RatingDefaults.initialRating
        }
        return ratings.reduce(0, +) / ratings.count
    }

    func ratingForParticipant(_ playerId: String, circleId: String) -> Int {
        if VisitorIdentity.isVisitor(playerId) {
            return VisitorIdentity.fixedRating
        }
        return ratingInCircle(circleId: circleId, userId: playerId)
    }

    func participantDisplayName(for playerId: String) -> String {
        if VisitorIdentity.isVisitor(playerId) {
            return authManager.visitorName(for: playerId) ?? VisitorIdentity.displayName
        }
        let name = members(in: authManager.currentCircleId ?? "")
            .first { $0.userId == playerId }?
            .userName ?? ""
        return name.isEmpty ? playerId : name
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

    func isUserParticipant(in match: MatchResult, userId: String) -> Bool {
        match.teamAPlayers.contains(userId)
            || match.teamBPlayers.contains(userId)
    }

    /// 指定ユーザーがその試合で受けたレート変動（保存値優先、未保存は算出）
    func userRatingChange(for match: MatchResult, userId: String) -> Int? {
        guard isMatchInCurrentCircle(match) else { return nil }
        guard isUserParticipant(in: match, userId: userId) else {
            return nil
        }

        if let stored = match.ratingChangesByUserId[userId] {
            return stored
        }

        return estimatedRatingChange(for: match, userId: userId)
    }

    func formattedRatingChange(_ change: Int) -> String {
        change >= 0 ? "+\(change)" : "\(change)"
    }

    private func members(in circleId: String) -> [CircleMembership] {
        authManager.currentCircleMembers.filter { $0.circleId == circleId }
    }

    private func currentMemberRatings(for circleId: String) -> [String: Int] {
        Dictionary(
            uniqueKeysWithValues: members(in: circleId).map {
                ($0.id, $0.rating)
            }
        )
    }

    private struct AppliedRatings {
        let memberRatings: [String: Int]
        let changesByUserId: [String: Int]
    }

    private func ratingsAfterApplying(
        match: MatchResult,
        sign: Int
    ) -> AppliedRatings {
        guard match.circleId == authManager.currentCircleId else {
            return AppliedRatings(memberRatings: [:], changesByUserId: [:])
        }

        var ratings = currentMemberRatings(for: match.circleId)
        var changesByUserId: [String: Int] = [:]

        applyMatchImpact(
            &ratings,
            match: match,
            sign: sign,
            circleId: match.circleId,
            recordChanges: sign > 0,
            changesByUserId: &changesByUserId
        )

        return AppliedRatings(
            memberRatings: ratings,
            changesByUserId: changesByUserId
        )
    }

    private func ratingChangesFromApplying(
        match: MatchResult,
        circleId: String
    ) -> [String: Int] {
        guard circleId == authManager.currentCircleId else { return [:] }

        var ratings = currentMemberRatings(for: circleId)
        var changesByUserId: [String: Int] = [:]

        applyMatchImpact(
            &ratings,
            match: match,
            sign: 1,
            circleId: circleId,
            recordChanges: true,
            changesByUserId: &changesByUserId
        )

        return changesByUserId
    }

    private func estimatedRatingChange(
        for match: MatchResult,
        userId: String
    ) -> Int? {
        guard isMatchInCurrentCircle(match) else { return nil }
        guard let rawDiff = playerRatingDelta(match: match, playerId: userId) else {
            return nil
        }

        let current = ratingInCircle(
            circleId: match.circleId,
            userId: userId
        )
        var adjustedDiff = rawDiff

        if rawDiff < 0 {
            adjustedDiff = Int(
                Double(rawDiff) * lossProtectionMultiplier(rating: current)
            )
        }

        let after = max(current + adjustedDiff, RatingRule.normal.minimumRating)
        return after - current
    }

    private func ratingInCircle(circleId: String, userId: String) -> Int {
        members(in: circleId)
            .first { $0.userId == userId }?
            .rating ?? RatingDefaults.initialRating
    }

    private func applyMatchImpact(
        _ ratings: inout [String: Int],
        match: MatchResult,
        sign: Int,
        circleId: String,
        rule: RatingRule = .normal,
        recordChanges: Bool = false,
        changesByUserId: inout [String: Int]
    ) {
        guard match.circleId == circleId,
              circleId == authManager.currentCircleId else {
            return
        }

        let members = members(in: circleId)
        let allPlayers = match.teamAPlayers + match.teamBPlayers

        for userId in allPlayers {
            if VisitorIdentity.isVisitor(userId) {
                continue
            }

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

            let updated = max(current + adjustedDiff, rule.minimumRating)
            ratings[member.id] = updated

            if sign > 0, recordChanges {
                changesByUserId[userId] = updated - current
            }
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
        participantDisplayName(for: userId)
    }
}
