import SwiftUI

struct MatchInputView: View {

    @ObservedObject var store: AppStore
    let onRegistered: () -> Void

    @State private var matchType: MatchType = .singles

    @State private var teamAPlayer1 = "服部"
    @State private var teamAPlayer2 = "山田"

    @State private var teamBPlayer1 = "佐藤"
    @State private var teamBPlayer2 = "鈴木"

    @State private var winner = "A"

    @State private var setScores: [SetScore] = [
        SetScore(teamAScore: "", teamBScore: "")
    ]

var playerOptions: [String] {
    store.currentCirclePlayers.map { $0.name }
}

    var body: some View {
        NavigationView {
            Form {

                Section(header: Text("試合形式")) {
                    Picker("試合形式", selection: $matchType) {
                        ForEach(MatchType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                Section(header: Text("チームA")) {
                    Picker("1人目", selection: $teamAPlayer1) {
                        ForEach(playerOptions, id: \.self) { player in
                            Text(player).tag(player)
                        }
                    }

                    if matchType == .doubles {
                        Picker("2人目", selection: $teamAPlayer2) {
                            ForEach(playerOptions, id: \.self) { player in
                                Text(player).tag(player)
                            }
                        }
                    }
                }

                Section(header: Text("チームB")) {
                    Picker("1人目", selection: $teamBPlayer1) {
                        ForEach(playerOptions, id: \.self) { player in
                            Text(player).tag(player)
                        }
                    }

                    if matchType == .doubles {
                        Picker("2人目", selection: $teamBPlayer2) {
                            ForEach(playerOptions, id: \.self) { player in
                                Text(player).tag(player)
                            }
                        }
                    }
                }

                Section(header: Text("スコア")) {
										ForEach(setScores.indices, id: \.self) { index in

												HStack {

														Text("セット\(index + 1)")
																.frame(width: 80, alignment: .leading)

														Spacer()

														HStack(spacing: 12) {

																TextField(
																		"A",
																		text: $setScores[index].teamAScore
																)
																.keyboardType(.numberPad)
																.multilineTextAlignment(.center)
																.frame(width: 50)

																Text("-")
																		.font(.headline)
																		.frame(width: 20)

																TextField(
																		"B",
																		text: $setScores[index].teamBScore
																)
																.keyboardType(.numberPad)
																.multilineTextAlignment(.center)
																.frame(width: 50)
														}
														.frame(width: 140)
												}
										}

                    Button("セットを追加") {
                        setScores.append(SetScore(teamAScore: "", teamBScore: ""))
                    }

                    if setScores.count > 1 {
                        Button("最後のセットを削除") {
                            setScores.removeLast()
                        }
                        .foregroundColor(.red)
                    }
                }

                Section(header: Text("勝者")) {
                    Picker("勝者", selection: $winner) {
                        Text("チームA").tag("A")
                        Text("チームB").tag("B")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                Section {
                    Button(action: registerMatch) {
                        Text("試合結果を登録する")
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle("試合入力")
        }
    }

func registerMatch() {
    let teamA = matchType == .singles
        ? [teamAPlayer1]
        : [teamAPlayer1, teamAPlayer2]

    let teamB = matchType == .singles
        ? [teamBPlayer1]
        : [teamBPlayer1, teamBPlayer2]

    let teamARating = store.averageRating(for: teamA)
    let teamBRating = store.averageRating(for: teamB)

    let ratingDiff = store.calculateEloDiff(
        playerRating: teamARating,
        opponentRating: teamBRating,
        didWin: winner == "A"
    )

let result = MatchResult(

    circleId: store.currentCircleId,

    date: Date(),

    matchType: matchType,

    teamAPlayers: teamA,

    teamBPlayers: teamB,

    setScores: setScores,

    winner: winner,

    ratingDiff: abs(ratingDiff)

)

    store.registerMatch(result)
    resetForm()
    onRegistered()
}

    func resetForm() {
        winner = "A"
        setScores = [
            SetScore(teamAScore: "", teamBScore: "")
        ]
    }
}
