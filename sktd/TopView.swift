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
                    Text("Rating")
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)

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
                        color: .black.opacity(0.12),
                        radius: 10,
                        x: 0,
                        y: 4
                    )
                }
                .padding()
                .padding(.bottom, 80)
            }
            .background(
                Color.black.ignoresSafeArea()
            )

            .navigationBarTitleDisplayMode(.inline)

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

// MARK: - Recent Match Card

struct RecentMatchCard: View {

    let match: MatchResult

    let currentUserName: String

    var isWin: Bool {

        if match.teamAPlayers.contains(
            currentUserName
        ) {

            return match.winner == "A"
        }

        if match.teamBPlayers.contains(
            currentUserName
        ) {

            return match.winner == "B"
        }

        return false
    }

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 10
        ) {

            // MARK: Header

            HStack {

                Text(
                    match.matchType.rawValue
                )
                .font(.caption)
                .fontWeight(.bold)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(

                    isWin
                    ? Color.orange.opacity(0.18)
                    : Color.gray.opacity(0.15)
                )
                .foregroundColor(
                    isWin
                    ? .orange
                    : .gray
                )
                .cornerRadius(999)

                Spacer()

                Text(
                    formatDate(match.date)
                )
                .font(.caption2)
                .foregroundColor(.gray)
            }

            // MARK: Team

            VStack(
                alignment: .leading,
                spacing: 6
            ) {

                HStack {

                    Text(
                        match.teamAPlayers.joined(
                            separator: " / "
                        )
                    )
                    .fontWeight(
                        match.winner == "A"
                        ? .bold
                        : .regular
                    )

                    if match.winner == "A" {

                        Text("👑")
                    }

                    Spacer()
                }

                HStack {

                    Text(
                        match.teamBPlayers.joined(
                            separator: " / "
                        )
                    )
                    .fontWeight(
                        match.winner == "B"
                        ? .bold
                        : .regular
                    )

                    if match.winner == "B" {

                        Text("👑")
                    }

                    Spacer()
                }
            }

            // MARK: Set Score

            HStack {

                ForEach(
                    match.setScores.indices,
                    id: \.self
                ) { index in

                    let score =
                        match.setScores[index]

                    Text(
                        "\(score.teamAScore)-\(score.teamBScore)"
                    )
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Color.orange.opacity(0.12)
                    )
                    .cornerRadius(10)
                }

                Spacer()

                Text(
                    isWin
                    ? "+\(match.ratingDiff)"
                    : "-\(match.ratingDiff)"
                )
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(
                    isWin
                    ? .orange
                    : .blue
                )
            }
        }
        .padding()
        .background(

            RoundedRectangle(
                cornerRadius: 18
            )
            .fill(Color.white)
        )
    }

    func formatDate(
        _ date: Date
    ) -> String {

        let formatter =
            DateFormatter()

        formatter.locale =
            Locale(identifier: "ja_JP")

        formatter.dateFormat =
            "MM/dd HH:mm"

        return formatter.string(
            from: date
        )
    }
}
