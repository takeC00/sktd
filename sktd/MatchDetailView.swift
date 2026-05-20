import SwiftUI

struct MatchDetailView: View {

    let match: MatchResult
		let currentUserName: String
	
		var isCurrentUserTeamA: Bool {
				match.teamAPlayers.contains(currentUserName)
		}

		var isWin: Bool {
				if isCurrentUserTeamA {
						return match.winner == "A"
				} else {
						return match.winner == "B"
				}
		}

		var signedRatingDiff: Int {
				isWin ? match.ratingDiff : -match.ratingDiff
		}

		var ratingDiffText: String {
				signedRatingDiff > 0
				? "+\(signedRatingDiff)"
				: "\(signedRatingDiff)"
		}

		var ratingDiffColor: Color {
				signedRatingDiff >= 0 ? .green : .red
		}
    var body: some View {
        List {
            Section(header: Text("試合情報")) {
                HStack {
                    Text("試合形式")
                    Spacer()
                    Text(match.matchType.rawValue)
                }

                HStack {
                    Text("日付")
                    Spacer()
                    Text(formatDate(match.date))
                }

                HStack {
                    Text("セット数")
                    Spacer()
                    Text("\(match.setScores.count)セット")
                }

                HStack {
                    Text("勝者")
                    Spacer()
                    Text(match.winner == "A" ? "チームA" : "チームB")
                }

                HStack {
                    Text("レート変動")
                    Spacer()
                    Text(ratingDiffText)
                        .foregroundColor(ratingDiffColor)
                }
            }

            Section(header: Text("チームA")) {
                ForEach(match.teamAPlayers, id: \.self) { player in
                    Text(player)
                }
            }

            Section(header: Text("チームB")) {
                ForEach(match.teamBPlayers, id: \.self) { player in
                    Text(player)
                }
            }

            Section(header: Text("ポイント")) {
                ForEach(Array(match.setScores.enumerated()), id: \.element.id) { index, score in
                    HStack {
                        Text("セット\(index + 1)")
                        Spacer()
                        Text("\(score.teamAScore) - \(score.teamBScore)")
                            .font(.headline)
                    }
                }
            }
        }
        .navigationTitle("試合詳細")
    }
}
