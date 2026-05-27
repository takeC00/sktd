import SwiftUI

struct TopView: View {

    @ObservedObject var store: AppStore

    @StateObject private var authManager =
        FirebaseAuthManager.shared

    @State private var showLogoutAlert = false

    var myRating: Int {

        store.ratingInCurrentCircle(
            userId: store.currentUserId
        )
    }

    var currentCircleMatches: [MatchResult] {

        store.matchResults.filter {
            $0.circleId == store.currentCircleId
        }
    }

    var ratingHistories: [Int] {

        let targetMatches = Array(
            currentCircleMatches
                .filter {

                    $0.teamAPlayers.contains(
                        store.currentUserName
                    )
                    ||
                    $0.teamBPlayers.contains(
                        store.currentUserName
                    )
                }
                .prefix(20)
        )

        let signedDiffs = targetMatches.map {
            match -> Int in

            if match.teamAPlayers.contains(
                store.currentUserName
            ) {

                return match.winner == "A"
                    ? match.ratingDiff
                    : -match.ratingDiff
            }

            if match.teamBPlayers.contains(
                store.currentUserName
            ) {

                return match.winner == "B"
                    ? match.ratingDiff
                    : -match.ratingDiff
            }

            return 0
        }

        let totalDiff =
            signedDiffs.reduce(0, +)

        var values = [
            myRating - totalDiff
        ]

        for diff in signedDiffs.reversed() {

            values.append(
                values.last! + diff
            )
        }

        return values
    }

    var recentMatches: [MatchResult] {

        Array(
            currentCircleMatches
                .filter {

                    $0.teamAPlayers.contains(
                        store.currentUserName
                    )
                    ||
                    $0.teamBPlayers.contains(
                        store.currentUserName
                    )
                }
                .prefix(3)
        )
    }

    var body: some View {

        NavigationView {

            ScrollView {

                VStack(
                    alignment: .leading,
                    spacing: 24
                ) {

                    // MARK: レーティング

                    VStack(
                        alignment: .leading,
                        spacing: 8
                    ) {

                        HStack(spacing: 6) {

                            Text("レーティング")
                                .font(.headline)
                                .foregroundColor(.gray)

                            NavigationLink(
                                destination:
                                    RatingExplanationView()
                            ) {

                                Image(
                                    systemName:
                                        "questionmark.circle"
                                )
                                .foregroundColor(.orange)
                                .font(.subheadline)
                            }
                        }
                    }

                    RankGaugeView(
                        rating: myRating
                    )
                    .frame(maxWidth: .infinity)

                    // MARK: レート推移

                    VStack(
                        alignment: .leading,
                        spacing: 12
                    ) {

                        HStack {

                            Text("レーティング推移")
                                .font(.headline)

                            Spacer()

                            Text("直近20試合")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }

                        RatingGraphView(
                            values: ratingHistories
                        )
                        .frame(height: 220)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(
                        color: .black.opacity(0.16),
                        radius: 10,
                        x: 0,
                        y: 4
                    )
                }
                .padding()
                .padding(.bottom, 80)
            }
            .navigationTitle("Rating")

            // MARK: ログアウト

            .toolbar {

                ToolbarItem(
                    placement: .topBarTrailing
                ) {

                    Button {

                        showLogoutAlert = true

                    } label: {

                        Image(
                            systemName:
                                "rectangle.portrait.and.arrow.right"
                        )
                        .foregroundColor(.red)
                    }
                }
            }

            // MARK: ログアウト確認

            .alert(
                "ログアウトしますか？",
                isPresented: $showLogoutAlert
            ) {

                Button(
                    "キャンセル",
                    role: .cancel
                ) {
                }

                Button(
                    "ログアウト",
                    role: .destructive
                ) {

                    authManager.logout()
                }

            } message: {

                Text(
                    "現在のアカウントからログアウトします。"
                )
            }
        }
    }
}

// MARK: - Rank Gauge

struct RankGaugeView: View {

    let rating: Int

    var rank: String {

        switch rating {

        case 2200...:
            return "SS"

        case 2000..<2200:
            return "S"

        case 1800..<2000:
            return "A"

        case 1600..<1800:
            return "B"

        case 1400..<1600:
            return "C"

        case 1200..<1400:
            return "D"

        case 1000..<1200:
            return "E"

        default:
            return "F"
        }
    }

    // MARK: ランクカラー

    var rankColor: Color {

        switch rank {

        case "SS":
            return Color.yellow

        case "S":
            return Color.orange

        case "A":
            return Color.pink

        case "B":
            return Color.purple

        case "C":
            return Color.blue

        case "D":
            return Color.green

        case "E":
            return Color(
                red: 0.55,
                green: 0.38,
                blue: 0.22
            )

        default:
            return Color.gray
        }
    }

    // MARK: 次ランクカラー

    var nextRankColor: Color {

        switch rank {

        case "F":
            return Color(
                red: 0.55,
                green: 0.38,
                blue: 0.22
            )

        case "E":
            return Color.green

        case "D":
            return Color.blue

        case "C":
            return Color.purple

        case "B":
            return Color.pink

        case "A":
            return Color.orange

        case "S":
            return Color.yellow

        default:
            return Color.yellow
        }
    }

    var nextRankRating: Int {

        switch rating {

        case 2200...:
            return rating

        case 2000..<2200:
            return 2200

        case 1800..<2000:
            return 2000

        case 1600..<1800:
            return 1800

        case 1400..<1600:
            return 1600

        case 1200..<1400:
            return 1400

        case 1000..<1200:
            return 1200

        default:
            return 1000
        }
    }

    var currentRankBaseRating: Int {

        switch rating {

        case 2200...:
            return 2200

        case 2000..<2200:
            return 2000

        case 1800..<2000:
            return 1800

        case 1600..<1800:
            return 1600

        case 1400..<1600:
            return 1400

        case 1200..<1400:
            return 1200

        case 1000..<1200:
            return 1000

        default:
            return 800
        }
    }

    var progress: Double {

        if rating >= 2200 {
            return 1.0
        }

        let range = max(
            nextRankRating - currentRankBaseRating,
            1
        )

        let current =
            rating - currentRankBaseRating

        return min(
            max(
                Double(current)
                / Double(range),
                0
            ),
            1
        )
    }

    var remainingPointText: String {

        if rating >= 2200 {
            return "最高ランク到達"
        }

        return "次ランクまであと \(nextRankRating - rating)"
    }

    var body: some View {

        VStack(spacing: 22) {

            // MARK: ランクバッジ

            ZStack {

                RoundedRectangle(
                    cornerRadius: 28
                )
                .fill(

                    LinearGradient(
                        colors: [
                            rankColor,
                            nextRankColor
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

                RoundedRectangle(
                    cornerRadius: 28
                )
                .fill(

                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.35),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .center
                    )
                )

                RoundedRectangle(
                    cornerRadius: 28
                )
                .stroke(
                    Color.white.opacity(0.22),
                    lineWidth: 2
                )

                VStack(spacing: 4) {

                    Text("RANK")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(
                            .white.opacity(0.85)
                        )

                    Text(rank)
                        .font(
                            .system(
                                size: 44,
                                weight: .black
                            )
                        )
                        .foregroundColor(.white)
                        .shadow(
                            color: .black.opacity(0.35),
                            radius: 4
                        )
                }
            }
            .frame(width: 140, height: 140)
            .shadow(
                color: rankColor.opacity(0.45),
                radius: 18
            )

            // MARK: レート

            VStack(spacing: 6) {

                Text("\(rating)")
                    .font(
                        .system(
                            size: 42,
                            weight: .black
                        )
                    )
                    .foregroundColor(.black)

                Text(remainingPointText)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            // MARK: Progress

            VStack(spacing: 16) {

                GaugeArcView(
                    progress: progress,
                    currentColor: rankColor,
                    nextColor: nextRankColor
                )
                .frame(height: 90)
            }
        }
        .padding(.top, 28)
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(
            color: .black.opacity(0.14),
            radius: 10,
            x: 0,
            y: 4
        )
    }
}

// MARK: - Gauge

struct GaugeArcView: View {

    let progress: Double

    let currentColor: Color
    let nextColor: Color

    var body: some View {

        GeometryReader { geo in

            let width = geo.size.width
            let height = geo.size.height

            let lineWidth: CGFloat = 24

            let radius = min(
                width * 0.42,
                height * 1.15
            )

            let center = CGPoint(
                x: width / 2,
                y: height * 1.05
            )

            ZStack {

                Path { path in

                    path.addArc(
                        center: center,
                        radius: radius,
                        startAngle: .degrees(205),
                        endAngle: .degrees(335),
                        clockwise: false
                    )
                }
                .stroke(
                    Color.gray.opacity(0.18),
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )

                Path { path in

                    path.addArc(
                        center: center,
                        radius: radius,
                        startAngle: .degrees(205),
                        endAngle: .degrees(
                            205 + 130 * progress
                        ),
                        clockwise: false
                    )
                }
                .stroke(
                    LinearGradient(
                        colors: [
                            currentColor,
                            nextColor
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
            }
        }
    }
}

// MARK: - Graph

struct RatingGraphView: View {

    let values: [Int]

    var maxValue: Int {
        values.max() ?? 1500
    }

    var minValue: Int {
        values.min() ?? 1500
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
        stride(
            from: upperValue,
            through: lowerValue,
            by: -50
        ).map { $0 }
    }

    var body: some View {

        GeometryReader { geometry in

            let chartWidth = geometry.size.width - 56
            let chartHeight = geometry.size.height - 40

            let leftPadding: CGFloat = 48
            let topPadding: CGFloat = 18

            ZStack {

                RoundedRectangle(cornerRadius: 18)
                    .fill(

                        LinearGradient(
                            colors: [
                                Color.orange.opacity(0.10),
                                Color.gray.opacity(0.04)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // グリッド

                ForEach(scaleValues, id: \.self) { value in

                    let yRatio =
                        CGFloat(value - lowerValue)
                        / CGFloat(range)

                    let y =
                        topPadding
                        + chartHeight * (1 - yRatio)

                    Path { path in

                        path.move(
                            to: CGPoint(
                                x: leftPadding,
                                y: y
                            )
                        )

                        path.addLine(
                            to: CGPoint(
                                x: leftPadding + chartWidth,
                                y: y
                            )
                        )
                    }
                    .stroke(
                        Color.gray.opacity(0.22),
                        lineWidth: 1
                    )

                    Text("\(value)")
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .position(x: 24, y: y)
                }

                // ライン

                Path { path in

                    for index in values.indices {

                        let x =
                            leftPadding
                            + chartWidth
                            * CGFloat(index)
                            / CGFloat(
                                max(values.count - 1, 1)
                            )

                        let yRatio =
                            CGFloat(values[index] - lowerValue)
                            / CGFloat(range)

                        let y =
                            topPadding
                            + chartHeight * (1 - yRatio)

                        if index == 0 {

                            path.move(
                                to: CGPoint(x: x, y: y)
                            )

                        } else {

                            path.addLine(
                                to: CGPoint(x: x, y: y)
                            )
                        }
                    }
                }
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(
                                red: 1.0,
                                green: 0.35,
                                blue: 0.05
                            ),
                            Color.orange,
                            Color(
                                red: 1.0,
                                green: 0.65,
                                blue: 0.15
                            )
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(
                        lineWidth: 4,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )

                // 点

                ForEach(values.indices, id: \.self) { index in

                    let x =
                        leftPadding
                        + chartWidth
                        * CGFloat(index)
                        / CGFloat(
                            max(values.count - 1, 1)
                        )

                    let yRatio =
                        CGFloat(values[index] - lowerValue)
                        / CGFloat(range)

                    let y =
                        topPadding
                        + chartHeight * (1 - yRatio)

                    Circle()
                        .fill(Color.white)
                        .frame(
                            width:
                                index == values.indices.last
                                ? 14
                                : 9,
                            height:
                                index == values.indices.last
                                ? 14
                                : 9
                        )
                        .overlay(

                            Circle()
                                .stroke(
                                    Color(
                                        red: 1.00,
                                        green: 0.42,
                                        blue: 0.08
                                    ),
                                    lineWidth: 2
                                )
                        )
                        .position(x: x, y: y)
                }
            }
        }
    }
}
