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
        applyRating(result)
    }

    private func applyRating(_ result: MatchResult) {
        for name in result.teamAPlayers {
            updateRating(
                playerName: name,
                diff: result.winner == "A" ? result.ratingDiff : -result.ratingDiff
            )
        }

        for name in result.teamBPlayers {
            updateRating(
                playerName: name,
                diff: result.winner == "B" ? result.ratingDiff : -result.ratingDiff
            )
        }
    }

    private func updateRating(playerName: String, diff: Int) {
        guard let player = players.first(where: { $0.name == playerName }) else {
            return
        }

        guard let index = circleMembers.firstIndex(where: {
            $0.userId == player.id &&
            $0.circleId == currentCircleId
        }) else {
            return
        }

        circleMembers[index].rating += diff
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
			kFactor: Double = 64,
			minimumChange: Int = 5,
			maximumChange: Int = 40
	) -> Int {

			let expectedScore =
					1.0 /
					(1.0 + pow(
							10.0,
							Double(opponentRating - playerRating) / 400.0
					))

			let actualScore = didWin ? 1.0 : 0.0

			let diff =
					kFactor *
					(actualScore - expectedScore)

			var rounded = Int(diff.rounded())

			if didWin {

					rounded = max(rounded, minimumChange)
					rounded = min(rounded, maximumChange)

			} else {

					rounded = min(rounded, -minimumChange)
					rounded = max(rounded, -maximumChange)
			}

			return rounded
	}
}
