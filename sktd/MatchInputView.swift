import SwiftUI

struct MatchInputView: View {

    @ObservedObject var store: AppStore
    let onRegistered: () -> Void

    @StateObject private var authManager =
        FirebaseAuthManager.shared

    @State private var matchType: MatchType = .singles

    @State private var teamAPlayer1 = ""
    @State private var teamAPlayer2 = ""

    @State private var teamBPlayer1 = ""
    @State private var teamBPlayer2 = ""

    @State private var winner = ""
    @State private var showRegisterConfirm = false

    @State private var setScores: [SetScore] = [
        SetScore(teamAScore: "", teamBScore: "")
    ]

    var playerOptions: [String] {
        authManager.currentCircleMembers.map { $0.userName }
    }

    var canRegister: Bool {
        !hasDuplicatePlayers && hasValidScore && !winner.isEmpty
    }

    var hasValidScore: Bool {
        setScores.contains { score in
            guard
                let a = Int(score.teamAScore),
                let b = Int(score.teamBScore)
            else {
                return false
            }

            return a != b
        }
    }

    var hasDuplicatePlayers: Bool {
        var players = [
            teamAPlayer1,
            teamBPlayer1
        ]

        if matchType == .doubles {
            players.append(teamAPlayer2)
            players.append(teamBPlayer2)
        }

        return Set(players).count != players.count
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        hideKeyboard()
                    }

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
                        playerPicker(
                            title: "1人目",
                            selection: $teamAPlayer1,
                            currentValue: teamAPlayer1
                        )

                        if matchType == .doubles {
                            playerPicker(
                                title: "2人目",
                                selection: $teamAPlayer2,
                                currentValue: teamAPlayer2
                            )
                        }
                    }

                    Section(header: Text("チームB")) {
                        playerPicker(
                            title: "1人目",
                            selection: $teamBPlayer1,
                            currentValue: teamBPlayer1
                        )

                        if matchType == .doubles {
                            playerPicker(
                                title: "2人目",
                                selection: $teamBPlayer2,
                                currentValue: teamBPlayer2
                            )
                        }
                    }

                    Section(header: Text("スコア")) {
                        ForEach(setScores.indices, id: \.self) { index in
                            HStack {
                                Text("セット\(index + 1)")
                                    .frame(width: 80, alignment: .leading)

                                Spacer()

                                HStack(spacing: 12) {
                                    TextField("A", text: $setScores[index].teamAScore)
                                        .keyboardType(.numberPad)
                                        .multilineTextAlignment(.center)
                                        .frame(width: 50)
                                        .onChange(of: setScores[index].teamAScore) {
                                            updateWinnerFromScores()
                                        }

                                    Text("-")
                                        .font(.headline)
                                        .frame(width: 20)

                                    TextField("B", text: $setScores[index].teamBScore)
                                        .keyboardType(.numberPad)
                                        .multilineTextAlignment(.center)
                                        .frame(width: 50)
                                        .onChange(of: setScores[index].teamBScore) {
                                            updateWinnerFromScores()
                                        }
                                }
                                .frame(width: 140)
                            }
                        }

                        Button("セットを追加") {
                            setScores.append(
                                SetScore(teamAScore: "", teamBScore: "")
                            )
                        }

                        if setScores.count > 1 {
                            Button("最後のセットを削除") {
                                setScores.removeLast()
                                updateWinnerFromScores()
                            }
                            .foregroundColor(.red)
                        }
                    }

                    Section(header: Text("勝者")) {
                        HStack {
                            Text("判定結果")
                            Spacer()

                            if winner.isEmpty {
                                Text("未判定")
                                    .foregroundColor(.gray)
                            } else {
                                Text(winner == "A" ? "チームA" : "チームB")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                            }
                        }
                    }

                    Section {
                        Button(action: {
                            hideKeyboard()
                            showRegisterConfirm = true
                        }) {
                            Text("試合結果を登録する")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                        }
                        .listRowBackground(canRegister ? Color.orange : Color.gray)
                        .disabled(!canRegister)
                    }
                }
            }
            .navigationTitle("試合入力")
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()

                    Button("閉じる") {
                        hideKeyboard()
                    }
                }
            }
            .alert(
                "試合結果を登録しますか？",
                isPresented: $showRegisterConfirm
            ) {
                Button("キャンセル", role: .cancel) {
                }

                Button("登録する") {
                    registerMatch()
                }
            } message: {
                Text("登録後、レーティングと試合履歴に反映されます。")
            }
        }
    }

    func playerPicker(
        title: String,
        selection: Binding<String>,
        currentValue: String
    ) -> some View {
        let selectablePlayers = playerOptions.filter {
            !isSelected($0, excluding: currentValue) || $0 == currentValue
        }

        return Picker(title, selection: selection) {
            ForEach(selectablePlayers, id: \.self) { player in
                Text(player)
                    .tag(player)
            }
        }
    }

    func selectedPlayers(excluding currentValue: String) -> [String] {
        var players = [
            teamAPlayer1,
            teamBPlayer1
        ]

        if matchType == .doubles {
            players.append(teamAPlayer2)
            players.append(teamBPlayer2)
        }

        return players.filter { $0 != currentValue }
    }

    func isSelected(_ player: String, excluding currentValue: String) -> Bool {
        selectedPlayers(excluding: currentValue).contains(player)
    }

    func updateWinnerFromScores() {
        var teamASetWins = 0
        var teamBSetWins = 0

        for score in setScores {
            guard
                let a = Int(score.teamAScore),
                let b = Int(score.teamBScore),
                a != b
            else {
                continue
            }

            if a > b {
                teamASetWins += 1
            } else {
                teamBSetWins += 1
            }
        }

        if teamASetWins > teamBSetWins {
            winner = "A"
        } else if teamBSetWins > teamASetWins {
            winner = "B"
        } else {
            winner = ""
        }
    }

    func registerMatch() {
        if !canRegister {
            return
        }

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
            didWin: winner == "A",
            rule: .normal
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
        winner = ""
        setScores = [
            SetScore(teamAScore: "", teamBScore: "")
        ]
    }
}

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}
