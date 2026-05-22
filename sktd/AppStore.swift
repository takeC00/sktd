import SwiftUI
import Combine

class AppStore: ObservableObject {

    @Published var players: [Player] = samplePlayers
    @Published var circles: [CircleGroup] = sampleCircleGroups
    @Published var circleMembers: [CircleMember] = sampleCircleMembers
    @Published var matchResults: [MatchResult] = []

    @Published var currentUserId: String = "user_001"
    @Published var currentUserName: String = "服部"
    @Published var currentCircleId: String = "circle_001"

    var currentCircle: CircleGroup? {
        circles.first { $0.id == currentCircleId }
    }

    var currentCirclePlayers: [Player] {
        let memberUserIds = circleMembers
            .filter { $0.circleId == currentCircleId }
            .map { $0.userId }

        return players.filter {
            memberUserIds.contains($0.id)
        }
    }

    func ratingInCurrentCircle(userId: String) -> Int {
        circleMembers.first {
            $0.userId == userId &&
            $0.circleId == currentCircleId
        }?.rating ?? 1500
    }

    func registerMatch(_ result: MatchResult) {
        matchResults.insert(result, at: 0)
        applyRating(result, rule: .normal)
    }

    private func applyRating(_ result: MatchResult, rule: RatingRule) {
        for name in result.teamAPlayers {
            updateRating(
                playerName: name,
                diff: result.winner == "A" ? result.ratingDiff : -result.ratingDiff,
                rule: rule
            )
        }

        for name in result.teamBPlayers {
            updateRating(
                playerName: name,
                diff: result.winner == "B" ? result.ratingDiff : -result.ratingDiff,
                rule: rule
            )
        }
    }

    private func updateRating(playerName: String, diff: Int, rule: RatingRule) {
        guard let player = players.first(where: { $0.name == playerName }) else {
            return
        }

        guard let index = circleMembers.firstIndex(where: {
            $0.userId == player.id &&
            $0.circleId == currentCircleId
        }) else {
            return
        }

        let currentRating = circleMembers[index].rating
        var adjustedDiff = diff

        if diff < 0 {
            let multiplier = lossProtectionMultiplier(
                rating: currentRating,
                rule: rule
            )

            adjustedDiff = Int(Double(diff) * multiplier)
        }

        let newRating = currentRating + adjustedDiff

        circleMembers[index].rating = max(newRating, rule.minimumRating)
    }

    func averageRating(for playerNames: [String]) -> Int {
        let ratings = playerNames.compactMap { name -> Int? in
            guard let player = players.first(where: { $0.name == name }) else {
                return nil
            }

            return ratingInCurrentCircle(userId: player.id)
        }

        if ratings.isEmpty {
            return 1500
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

		func revertRating(_ result: MatchResult) {

				for name in result.teamAPlayers {

						updateRating(
								playerName: name,
								diff: result.winner == "A"
										? -result.ratingDiff
										: result.ratingDiff,
								rule: .normal
						)
				}

				for name in result.teamBPlayers {

						updateRating(
								playerName: name,
								diff: result.winner == "B"
										? -result.ratingDiff
										: result.ratingDiff,
								rule: .normal
						)
				}
		}
		func updateMatch(_ updated: MatchResult) {

				guard let index = matchResults.firstIndex(where: {
						$0.id == updated.id
				}) else {
						return
				}

				let oldMatch = matchResults[index]

				// 元レート巻き戻し
				revertRating(oldMatch)

				// 試合更新
				matchResults[index] = updated

				// 再計算
				applyRating(updated, rule: .normal)
		}
}
