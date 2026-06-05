import SwiftUI

struct MatchDetailView: View {

    @ObservedObject var store: AppStore

    let match: MatchResult

    @State private var showEditSheet = false

    private var currentUserId: String {
        store.currentUserId
    }

    private var myRatingChange: Int? {
        store.userRatingChange(for: match, userId: currentUserId)
    }

    var body: some View {

        ScrollView {

            VStack(
                alignment: .leading,
                spacing: 24
            ) {

                // MARK: 対戦カード

                VStack(
                    alignment: .leading,
                    spacing: 12
                ) {

                    Text("対戦カード")
                        .font(.headline)
                        .foregroundColor(.gray)

                    HStack(spacing: 8) {

                        teamLabel(
                            players: match.teamAPlayers,
                            isWinner: match.winner == "A"
                        )

                        Text("vs")
                            .foregroundStyle(.gray)

                        teamLabel(
                            players: match.teamBPlayers,
                            isWinner: match.winner == "B"
                        )
                    }
                    .font(.title3.bold())
                }

                // MARK: スコア

                VStack(
                    alignment: .leading,
                    spacing: 12
                ) {

                    Text("セットスコア")
                        .font(.headline)
                        .foregroundColor(.gray)

                    VStack(spacing: 10) {

                        ForEach(
                            match.setScores.indices,
                            id: \.self
                        ) { index in

                            let score = match.setScores[index]

                            HStack {

                                Text("セット\(index + 1)")
                                    .foregroundColor(.white)

                                Spacer()

                                HStack(spacing: 8) {

                                    HStack(spacing: 2) {

                                        Text(score.teamAScore)
                                    }

                                    Text("-")
                                        .foregroundColor(.gray)

                                    HStack(spacing: 2) {

                                        Text(score.teamBScore)
                                    }
                                }
                                .fontWeight(.bold)
                                .font(.title3)
                                .foregroundColor(.white)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        Color.white.opacity(0.06)
                                    )
                            )
                        }
                    }
                }

                // MARK: レート変動（自分が出場した試合のみ）

                if let change = myRatingChange {

                    VStack(
                        alignment: .leading,
                        spacing: 12
                    ) {

                        Text("レーティング変動")
                            .font(.headline)
                            .foregroundColor(.gray)

                        Text(store.formattedRatingChange(change))
                            .font(.system(size: 36, weight: .heavy))
                            .foregroundColor(
                                change >= 0
                                ? .orange
                                : .blue
                            )
                    }
                }

                // MARK: 日時

                VStack(
                    alignment: .leading,
                    spacing: 12
                ) {

                    Text("試合日時")
                        .font(.headline)
                        .foregroundColor(.gray)

                    Text(formatDate(match.date))
                        .foregroundColor(.white)
                }
            }
            .padding()
        }
        .background(
            Color.black.ignoresSafeArea()
        )
        .foregroundStyle(.white)
        .tint(.white)
        .navigationTitle("試合詳細")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)

        // MARK: 編集画面

        .sheet(isPresented: $showEditSheet) {

            MatchEditView(
                store: store,
                originalMatch: match
            )
        }

        // MARK: 編集ボタン

        .toolbar {

            if match.id == store.matchesForCurrentCircle.first?.id {

                ToolbarItem(
                    placement: .topBarTrailing
                ) {

                    Button {

                        showEditSheet = true

                    } label: {

                        Image(systemName: "square.and.pencil")
                            .font(
                                .system(
                                    size: 20,
                                    weight: .bold
                                )
                            )
                            .frame(width: 44, height: 44)
                    }
                }
            }
        }
    }

    // MARK: 日付整形

    func formatDate(_ date: Date) -> String {

        let formatter = DateFormatter()

        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy/MM/dd HH:mm"

        return formatter.string(from: date)
    }

    private func teamLabel(players: [String], isWinner: Bool) -> some View {
        let containsSelf = players.contains(currentUserId)
        let nameColor: Color = containsSelf ? .orange : .white

        return HStack(spacing: 4) {
            Text(
                players.map { store.memberName(for: $0) }.joined(separator: "・")
            )
            .foregroundStyle(nameColor)

            if isWinner {
                Image(systemName: "crown.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.blue)
            }
        }
    }
}
