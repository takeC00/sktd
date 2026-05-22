import SwiftUI

struct MatchHistoryView: View {

    @ObservedObject var store: AppStore
		@State private var editingMatch: MatchResult?
    var currentCircleHistories: [MatchResult] {
        store.matchResults.filter {
            $0.circleId == store.currentCircleId
        }
    }

    var groupedHistories: [String: [MatchResult]] {
        Dictionary(grouping: currentCircleHistories) {
            formatOnlyDate($0.date)
        }
    }

    var sortedDates: [String] {
        groupedHistories.keys.sorted(by: >)
    }

    var body: some View {
        NavigationView {
            List {
                if currentCircleHistories.isEmpty {
                    Text("まだ試合履歴がありません")
                        .foregroundColor(.gray)
                } else {
                    ForEach(sortedDates, id: \.self) { date in
												MatchHistoryDateSection(
														date: date,
														histories: groupedHistories[date] ?? [],
														currentUserName: store.currentUserName,
														store: store,
														editingMatch: $editingMatch
												)
                    }
                }
            }
            .navigationTitle("試合履歴")
						.sheet(item: $editingMatch) { match in
								MatchEditView(
										store: store,
										originalMatch: match
								)
						}
        }
    }
}

struct MatchHistoryDateSection: View {

    let date: String
    let histories: [MatchResult]
		let currentUserName: String
		let store: AppStore
		@Binding var editingMatch: MatchResult?

    var body: some View {

        Section(header: Text(date)) {

            ForEach(histories) { history in

								VStack(alignment: .leading) {

										NavigationLink(
												destination: MatchDetailView(
														match: history,
														currentUserName: currentUserName
												)
										) {

												MatchHistoryRowView(
														history: history,
														currentUserName: currentUserName,
														showOnlyOpponent: false
												)
										}

										if history.id == histories.first?.id {

												Button("試合を編集") {
														editingMatch = history
												}
												.font(.caption)
												.foregroundColor(.orange)
										}
								}
            }
        }
    }
}

struct MatchHistoryRowView: View {

    let history: MatchResult
    let currentUserName: String
    let showOnlyOpponent: Bool

    var isCurrentUserTeamA: Bool {
        history.teamAPlayers.contains(currentUserName)
    }

    var isCurrentUserTeamB: Bool {
        history.teamBPlayers.contains(currentUserName)
    }

    var isCurrentUserMatch: Bool {
        isCurrentUserTeamA || isCurrentUserTeamB
    }

    var isWin: Bool {
        if isCurrentUserTeamA {
            return history.winner == "A"
        }

        if isCurrentUserTeamB {
            return history.winner == "B"
        }

        return false
    }

    var teamAText: String {
        history.teamAPlayers.joined(separator: " / ")
    }

    var teamBText: String {
        history.teamBPlayers.joined(separator: " / ")
    }

    var opponentText: String {
        if isCurrentUserTeamA {
            return teamBText
        }

        if isCurrentUserTeamB {
            return teamAText
        }

        return teamBText
    }

    var listMainText: String {
        let teamA = history.winner == "A" ? "👑 \(teamAText)" : teamAText
        let teamB = history.winner == "B" ? "👑 \(teamBText)" : teamBText

        return "\(teamA) vs \(teamB)"
    }

		var partnerText: String {
				if isCurrentUserTeamA {
						return history.teamAPlayers
								.filter { $0 != currentUserName }
								.joined(separator: " / ")
				}

				if isCurrentUserTeamB {
						return history.teamBPlayers
								.filter { $0 != currentUserName }
								.joined(separator: " / ")
				}

				return ""
		}

		var myTeamText: String {
				if partnerText.isEmpty {
						return currentUserName
				}

				return "\(currentUserName) / \(partnerText)"
		}

		var topMainText: String {
				if showOnlyOpponent && isCurrentUserMatch {
						return "\(myTeamText) vs \(opponentText)"
				}

				return listMainText
		}

    var signedRatingDiff: Int {
        isWin ? history.ratingDiff : -history.ratingDiff
    }

    var ratingDiffText: String {
        signedRatingDiff > 0 ? "+\(signedRatingDiff)" : "\(signedRatingDiff)"
    }

    var ratingDiffColor: Color {
        signedRatingDiff >= 0 ? .green : .red
    }

    var resultText: String {
        isWin ? "勝利" : "敗北"
    }

    var resultColor: Color {
        isWin ? .gray : .red
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(showOnlyOpponent ? topMainText : listMainText)
                    .font(.headline)

                if showOnlyOpponent {
                    Text(resultText)
                        .font(.caption)
                        .foregroundColor(resultColor)
                }
            }

            Spacer()

            if showOnlyOpponent {
                Text(ratingDiffText)
                    .font(.headline)
                    .foregroundColor(ratingDiffColor)
            }
        }
        .padding(.vertical, 6)
    }
}
