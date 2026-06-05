import SwiftUI

struct TopView: View {

    @ObservedObject var store: AppStore

    @StateObject private var authManager =
        FirebaseAuthManager.shared

    @State private var showAccountSettings = false

    var myRating: Int {
        store.ratingInCurrentCircle(userId: store.currentUserId)
    }

    var ratingHistories: [Int] {
        store.ratingHistory(for: store.currentUserId)
    }

    var recentMatches: [MatchResult] {
        store.participantMatchesForCurrentCircle(
            userId: store.currentUserId,
            limit: 3
        )
    }

    private var currentCircleName: String? {
        guard let circleId = authManager.currentCircleId else { return nil }
        return authManager.joinedCircles.first { $0.id == circleId }?.name
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
                            VStack(alignment: .leading, spacing: 2) {
                                Text("レーティング")
                                    .font(.headline)
                                    .foregroundColor(.gray)

                                if let circleName = currentCircleName {
                                    Text(circleName)
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                            }

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
            .refreshable {
                authManager.refreshCircles()
                store.startListeningMatches()
            }
            .background(
                Color.black.ignoresSafeArea()
            )

            .navigationTitle("Rating")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)

            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    AccountToolbarMenu(showAccountSettings: $showAccountSettings)
                }
            }
            .accountSettingsSheet(isPresented: $showAccountSettings)
            .onAppear {
                authManager.refreshCircles()
                store.startListeningMatches()
            }
            .onChange(of: authManager.currentCircleId) { _, _ in
                authManager.fetchCurrentCircleMembers()
                store.startListeningMatches()
            }
        }
    }
}

// MARK: - Recent Match Card

struct RecentMatchCard: View {

    let match: MatchResult

    let store: AppStore
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
                        match.teamAPlayers.map { store.memberName(for: $0) }.joined(
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
                        match.teamBPlayers.map { store.memberName(for: $0) }.joined(
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
