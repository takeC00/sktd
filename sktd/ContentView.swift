import SwiftUI

struct Player: Identifiable {
    let id = UUID()
    let name: String
    let rating: Int
}
struct MatchResult: Identifiable {

    let id = UUID()

    let date: Date

    let matchType: MatchType

    let teamAPlayers: [String]

    let teamBPlayers: [String]

    let setScores: [SetScore]

    let winner: String

    let ratingDiff: Int

}

struct SetScore: Identifiable {

    let id = UUID()

    var teamAScore: String

    var teamBScore: String

}

enum MatchType: String, CaseIterable {

    case singles = "シングルス"

    case doubles = "ダブルス"

}
let samplePlayers: [Player] = [
    Player(name: "服部", rating: 1680),
    Player(name: "佐藤", rating: 1520),
    Player(name: "楢村", rating: 1450),
    Player(name: "福田", rating: 1390)
]

struct ContentView: View {
    var body: some View {
        TabView {
            TopView()
                .tabItem {
                    Label("TOP", systemImage: "house")
                }

            MatchInputView()
                .tabItem {
                    Label("試合入力", systemImage: "plus.circle")
                }

            MatchHistoryView()
                .tabItem {
                    Label("履歴", systemImage: "clock")
                }

            RankingView()
                .tabItem {
                    Label("ランキング", systemImage: "crown")
                }
        }
    }
}

struct TopView: View {

    let currentRating = 1520

    let ratingHistories: [Int] = [
        1400, 1420, 1390, 1450, 1480, 1520
    ]

    let recentMatches: [String] = [
        "服部に勝利　+24",
        "内田に敗北　-18",
        "楢村に勝利　+21"
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    VStack(alignment: .leading, spacing: 8) {
                        Text("現在レーティング")
                            .font(.headline)
                            .foregroundColor(.gray)

                        Text("\(currentRating)")
                            .font(.system(size: 48, weight: .bold))
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("レーティング推移")
                            .font(.headline)

                        RatingGraphView(values: ratingHistories)
                            .frame(height: 180)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("直近の試合履歴")
                            .font(.headline)

                        ForEach(recentMatches, id: \.self) { match in
                            HStack {
                                Text(match)
                                Spacer()
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("TOP")
        }
    }
}

struct RatingGraphView: View {

    let values: [Int]

    var maxValue: Int {
        values.max() ?? 1
    }

    var minValue: Int {
        values.min() ?? 0
    }

    var upperValue: Int {
        ((maxValue + 50) / 50) * 50
    }

    var lowerValue: Int {
        max(((minValue - 50) / 50) * 50, 0)
    }

    var range: Int {
        max(upperValue - lowerValue, 1)
    }

    var scaleValues: [Int] {
        stride(from: upperValue, through: lowerValue, by: -50).map { $0 }
    }

    var body: some View {
        GeometryReader { geometry in

            let chartWidth = geometry.size.width - 48
            let chartHeight = geometry.size.height - 32
            let leftPadding: CGFloat = 44
            let topPadding: CGFloat = 12

            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray.opacity(0.08))

                // 横メモリ線 + 数値
                ForEach(scaleValues, id: \.self) { value in
                    let yRatio = CGFloat(value - lowerValue) / CGFloat(range)
                    let y = topPadding + chartHeight * (1 - yRatio)

                    Path { path in
                        path.move(to: CGPoint(x: leftPadding, y: y))
                        path.addLine(to: CGPoint(x: leftPadding + chartWidth, y: y))
                    }
                    .stroke(Color.gray.opacity(0.25), lineWidth: 1)

                    Text("\(value)")
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .position(x: 22, y: y)
                }

                // 折れ線
                Path { path in
                    for index in values.indices {
                        let x = leftPadding + chartWidth * CGFloat(index) / CGFloat(max(values.count - 1, 1))
                        let yRatio = CGFloat(values[index] - lowerValue) / CGFloat(range)
                        let y = topPadding + chartHeight * (1 - yRatio)

                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(Color.blue, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

                // ポイント
                ForEach(values.indices, id: \.self) { index in
                    let x = leftPadding + chartWidth * CGFloat(index) / CGFloat(max(values.count - 1, 1))
                    let yRatio = CGFloat(values[index] - lowerValue) / CGFloat(range)
                    let y = topPadding + chartHeight * (1 - yRatio)

                    Circle()
                        .fill(Color.white)
                        .frame(width: 10, height: 10)
                        .overlay(
                            Circle()
                                .stroke(Color.blue, lineWidth: 2)
                        )
                        .position(x: x, y: y)
                }
            }
        }
    }
}

struct RankingView: View {

    var rankedPlayers: [Player] {
        samplePlayers.sorted {
            $0.rating > $1.rating
        }
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(Array(rankedPlayers.enumerated()), id: \.element.id) { index, player in
                    HStack(spacing: 12) {
                        Text("\(index + 1)")
                            .font(.headline)
                            .frame(width: 32, height: 32)
                            .background(rankColor(index: index))
                            .foregroundColor(.white)
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 4) {
                            Text(player.name)
                                .font(.headline)

                            Text("Rating \(player.rating)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 6)
                }
            }
            .navigationTitle("ランキング")
        }
    }

    func rankColor(index: Int) -> Color {
        switch index {
        case 0:
            return .yellow
        case 1:
            return .gray
        case 2:
            return .orange
        default:
            return .blue
        }
    }
}

struct MatchInputView: View {

    @State private var matchType: MatchType = .singles

    @State private var teamAPlayer1 = "自分"
    @State private var teamAPlayer2 = "山田"

    @State private var teamBPlayer1 = "佐藤"
    @State private var teamBPlayer2 = "鈴木"

    @State private var winner = "A"

    @State private var setScores: [SetScore] = [
        SetScore(teamAScore: "", teamBScore: "")
    ]

    let playerOptions = [
        "自分",
        "山田",
        "佐藤",
        "鈴木",
        "高橋",
        "田中"
    ]

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

                            Spacer()

                            TextField("A", text: $setScores[index].teamAScore)
                                .keyboardType(.numberPad)
                                .frame(width: 50)

                            Text("-")

                            TextField("B", text: $setScores[index].teamBScore)
                                .keyboardType(.numberPad)
                                .frame(width: 50)
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
                    Button(action: {
                        let teamA = matchType == .singles
                            ? [teamAPlayer1]
                            : [teamAPlayer1, teamAPlayer2]

                        let teamB = matchType == .singles
                            ? [teamBPlayer1]
                            : [teamBPlayer1, teamBPlayer2]

                        let result = MatchResult(
                            date: Date(),
                            matchType: matchType,
                            teamAPlayers: teamA,
                            teamBPlayers: teamB,
                            setScores: setScores,
                            winner: winner,
                            ratingDiff: winner == "A" ? 24 : -24
                        )

                        print(result)
                    }) {
                        Text("試合結果を登録する")
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle("試合入力")
        }
    }
}

struct MatchHistory: Identifiable {
    let id = UUID()
    let date: String
    let opponent: String
    let result: String
    let ratingDiff: Int
}

let sampleMatchHistories: [MatchHistory] = [
    MatchHistory(date: "2026/05/20", opponent: "山田", result: "勝利", ratingDiff: 24),
    MatchHistory(date: "2026/05/20", opponent: "佐藤", result: "敗北", ratingDiff: -18),
    MatchHistory(date: "2026/05/18", opponent: "鈴木", result: "勝利", ratingDiff: 21)
]

struct MatchHistoryView: View {

    var groupedHistories: [String: [MatchHistory]] {
        Dictionary(grouping: sampleMatchHistories) { $0.date }
    }

    var sortedDates: [String] {
        groupedHistories.keys.sorted(by: >)
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(sortedDates, id: \.self) { date in
                    Section(header: Text(date)) {
                        ForEach(groupedHistories[date] ?? []) { history in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("vs \(history.opponent)")
                                        .font(.headline)

                                    Text(history.result)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }

                                Spacer()

                                Text(history.ratingDiff > 0 ? "+\(history.ratingDiff)" : "\(history.ratingDiff)")
                                    .font(.headline)
                                    .foregroundColor(history.ratingDiff > 0 ? .green : .red)
                            }
                            .padding(.vertical, 6)
                        }
                    }
                }
            }
            .navigationTitle("試合履歴")
        }
    }
}

struct MatchDetailView: View {

    let match: MatchResult

    var body: some View {
        List {
            Section(header: Text("試合情報")) {
                HStack {
                    Text("試合形式")
                    Spacer()
                    Text(match.matchType.rawValue)
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
                    Text(match.ratingDiff > 0 ? "+\(match.ratingDiff)" : "\(match.ratingDiff)")
                        .foregroundColor(match.ratingDiff > 0 ? .green : .red)
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

