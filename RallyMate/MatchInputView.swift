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
        authManager.currentCircleMembers.map { $0.userId }
    }

    func displayName(for userId: String) -> String {
        authManager.currentCircleMembers.first(where: { $0.userId == userId })?.userName
        ?? userId
    }

    var canRegister: Bool {
        hasSelectedRequiredPlayers
        && !hasDuplicatePlayers
        && hasValidScore
        && !winner.isEmpty
    }

    var hasSelectedRequiredPlayers: Bool {
        if matchType == .singles {
            return !teamAPlayer1.isEmpty && !teamBPlayer1.isEmpty
        }
        return !teamAPlayer1.isEmpty
        && !teamAPlayer2.isEmpty
        && !teamBPlayer1.isEmpty
        && !teamBPlayer2.isEmpty
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

        let selected = players.filter { !$0.isEmpty }
        return Set(selected).count != selected.count
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.black
                    .ignoresSafeArea()

                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        hideKeyboard()
                    }

                Form {
                    Section(header: Text("試合形式").foregroundColor(.gray)) {
                        Picker("試合形式", selection: $matchType) {
                            ForEach(MatchType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .tint(.orange)
                        // 未選択側が薄くて見づらいので、セグメント自体をダーク寄りに
                        .environment(\.colorScheme, .dark)
                    }
                    .listRowBackground(Color.white.opacity(0.06))

                    Section(header: Text("チームA").foregroundColor(.gray)) {
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
                    .listRowBackground(Color.white.opacity(0.06))

                    Section(header: Text("チームB").foregroundColor(.gray)) {
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
                    .listRowBackground(Color.white.opacity(0.06))

                    Section(header: Text("スコア").foregroundColor(.gray)) {
                        ForEach(setScores.indices, id: \.self) { index in
                            HStack {
                                Text("セット\(index + 1)")
                                    .frame(width: 80, alignment: .leading)
                                    .foregroundColor(.white)

                                Spacer()

                                HStack(spacing: 12) {
                                    TextField("A", text: $setScores[index].teamAScore)
                                        .keyboardType(.numberPad)
                                        .multilineTextAlignment(.center)
                                        .frame(width: 50)
                                        .foregroundColor(.white)
                                        .onChange(of: setScores[index].teamAScore) {
                                            updateWinnerFromScores()
                                        }

                                    Text("-")
                                        .font(.headline)
                                        .frame(width: 20)
                                        .foregroundColor(.gray)

                                    TextField("B", text: $setScores[index].teamBScore)
                                        .keyboardType(.numberPad)
                                        .multilineTextAlignment(.center)
                                        .frame(width: 50)
                                        .foregroundColor(.white)
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
                    .listRowBackground(Color.white.opacity(0.06))

                    Section(header: Text("勝者").foregroundColor(.gray)) {
                        HStack {
                            Text("判定結果")
                                .foregroundColor(.white)
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
                    .listRowBackground(Color.white.opacity(0.06))

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
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("試合入力")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                // 画面表示時点で members が空のことがあるので再取得
                authManager.fetchCurrentCircleMembers()
            }
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
            Text("選択してください").tag("")
            ForEach(selectablePlayers, id: \.self) { player in
                Text(displayName(for: player))
                    .tag(player)
            }
        }
        .pickerStyle(.menu)
        .foregroundColor(.white)
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

        return players
            .filter { !$0.isEmpty }
            .filter { $0 != currentValue }
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
            id: "",
            circleId: store.currentCircleId,
            date: Date(),
            matchType: matchType,
            teamAPlayers: teamA,
            teamBPlayers: teamB,
            setScores: setScores,
            winner: winner,
            ratingDiff: abs(ratingDiff)
        )

        store.registerMatch(result) { error in
            if error == nil {
                resetForm()
                onRegistered()
            }
        }
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
