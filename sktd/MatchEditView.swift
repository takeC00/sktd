import SwiftUI

struct MatchEditView: View {

    @Environment(\.dismiss) var dismiss

    @ObservedObject var store: AppStore

    let originalMatch: MatchResult

    @State private var matchType: MatchType

    @State private var teamAPlayer1: String
    @State private var teamAPlayer2: String

    @State private var teamBPlayer1: String
    @State private var teamBPlayer2: String

    @State private var setScores: [SetScore]

    init(
        store: AppStore,
        originalMatch: MatchResult
    ) {

        self.store = store
        self.originalMatch = originalMatch

        _matchType = State(
            initialValue: originalMatch.matchType
        )

        _teamAPlayer1 = State(
            initialValue: originalMatch.teamAPlayers.first ?? ""
        )

        _teamAPlayer2 = State(
            initialValue:
                originalMatch.teamAPlayers.count > 1
                ? originalMatch.teamAPlayers[1]
                : ""
        )

        _teamBPlayer1 = State(
            initialValue: originalMatch.teamBPlayers.first ?? ""
        )

        _teamBPlayer2 = State(
            initialValue:
                originalMatch.teamBPlayers.count > 1
                ? originalMatch.teamBPlayers[1]
                : ""
        )

        _setScores = State(
            initialValue: originalMatch.setScores
        )
    }

    var playerOptions: [String] {
        store.currentCirclePlayers.map { $0.name }
    }

    var body: some View {

        NavigationView {

            Form {

                // MARK: 試合形式

                Section(header: Text("試合形式")) {

                    Picker(
                        "試合形式",
                        selection: $matchType
                    ) {

                        ForEach(
                            MatchType.allCases,
                            id: \.self
                        ) { type in

                            Text(type.rawValue)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // MARK: チームA

                Section(header: Text("チームA")) {

                    Picker(
                        "1人目",
                        selection: $teamAPlayer1
                    ) {

                        ForEach(
                            playerOptions,
                            id: \.self
                        ) {
                            Text($0)
                        }
                    }

                    if matchType == .doubles {

                        Picker(
                            "2人目",
                            selection: $teamAPlayer2
                        ) {

                            ForEach(
                                playerOptions,
                                id: \.self
                            ) {
                                Text($0)
                            }
                        }
                    }
                }

                // MARK: チームB

                Section(header: Text("チームB")) {

                    Picker(
                        "1人目",
                        selection: $teamBPlayer1
                    ) {

                        ForEach(
                            playerOptions,
                            id: \.self
                        ) {
                            Text($0)
                        }
                    }

                    if matchType == .doubles {

                        Picker(
                            "2人目",
                            selection: $teamBPlayer2
                        ) {

                            ForEach(
                                playerOptions,
                                id: \.self
                            ) {
                                Text($0)
                            }
                        }
                    }
                }

                // MARK: スコア

								Section(header: Text("セットスコア")) {

										ForEach(
												setScores.indices,
												id: \.self
										) { index in

												HStack {

														Spacer()

														TextField(
																"A",
																text: $setScores[index].teamAScore
														)
														.keyboardType(.numberPad)
														.multilineTextAlignment(.center)
														.frame(width: 60)

														Text("-")
																.font(.headline)
																.frame(width: 24)

														TextField(
																"B",
																text: $setScores[index].teamBScore
														)
														.keyboardType(.numberPad)
														.multilineTextAlignment(.center)
														.frame(width: 60)

														Spacer()
												}
										}
								}

                // MARK: 保存

                Button {

                    save()

                } label: {

                    Text("保存")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                }
                .listRowBackground(Color.orange)
            }
            .navigationTitle("試合編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                ToolbarItem(
                    placement: .topBarLeading
                ) {

                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: 勝者判定

    func calculateWinner() -> String {

        var aWins = 0
        var bWins = 0

        for score in setScores {

            guard
                let a = Int(score.teamAScore),
                let b = Int(score.teamBScore)
            else {
                continue
            }

            if a > b {
                aWins += 1
            } else if b > a {
                bWins += 1
            }
        }

        return aWins > bWins ? "A" : "B"
    }

    // MARK: 保存処理

    func save() {

        let teamAPlayers =
            matchType == .singles
            ? [teamAPlayer1]
            : [teamAPlayer1, teamAPlayer2]

        let teamBPlayers =
            matchType == .singles
            ? [teamBPlayer1]
            : [teamBPlayer1, teamBPlayer2]

        let winner = calculateWinner()

        let updated = MatchResult(
            id: originalMatch.id,
            circleId: originalMatch.circleId,
            date: originalMatch.date,
            matchType: matchType,
            teamAPlayers: teamAPlayers,
            teamBPlayers: teamBPlayers,
            setScores: setScores,
            winner: winner,
            ratingDiff: originalMatch.ratingDiff
        )

        store.updateMatch(updated)

        dismiss()
    }
}
