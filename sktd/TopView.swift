import SwiftUI

struct TopView: View {

    @ObservedObject var store: AppStore

    var myRating: Int {
        store.ratingInCurrentCircle(userId: store.currentUserId)
    }

    var currentCircleMatches: [MatchResult] {
        store.matchResults.filter {
            $0.circleId == store.currentCircleId
        }
    }

		var ratingHistories: [Int] {

				let recentMatches = Array(
						currentCircleMatches
								.filter {
										$0.teamAPlayers.contains(store.currentUserName) ||
										$0.teamBPlayers.contains(store.currentUserName)
								}
								.prefix(20)
				)

				let signedDiffs = recentMatches.map { match -> Int in

						if match.teamAPlayers.contains(store.currentUserName) {
								return match.winner == "A" ? match.ratingDiff : -match.ratingDiff
						}

						if match.teamBPlayers.contains(store.currentUserName) {
								return match.winner == "B" ? match.ratingDiff : -match.ratingDiff
						}

						return 0
				}

				let totalDiff = signedDiffs.reduce(0, +)

				var values = [
						myRating - totalDiff
				]

				for diff in signedDiffs.reversed() {
						values.append(values.last! + diff)
				}

				return values
		}

    var recentMatches: [MatchResult] {
        Array(currentCircleMatches.prefix(3))
    }

    var body: some View {

        NavigationView {

            ScrollView {

                VStack(alignment: .leading, spacing: 24) {

                    VStack(alignment: .leading, spacing: 8) {

                        Text("現在レーティング")
                            .font(.headline)
                            .foregroundColor(.gray)

                        Text("\(myRating)")
                            .font(.system(size: 48, weight: .bold))

                        NavigationLink(
                            destination: RatingExplanationView()
                        ) {

                            Label(
                                "レーティングの計算方法",
                                systemImage: "questionmark.circle"
                            )
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }

                    VStack(alignment: .leading, spacing: 12) {

                        HStack {

                            Text("レーティング推移")
                                .font(.headline)

                            Spacer()

                            Text("直近20試合")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }

                        RatingGraphView(values: ratingHistories)
                            .frame(height: 220)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(radius: 4)

                    VStack(alignment: .leading, spacing: 12) {

                        Text("直近の試合履歴")
                            .font(.headline)

                        if recentMatches.isEmpty {

                            Text("まだ試合履歴がありません")
                                .foregroundColor(.gray)

                        } else {

                            ForEach(recentMatches) { match in

                                MatchHistoryRowView(history: match)
                                    .padding()
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(12)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("TOP")
        }
    }
}
