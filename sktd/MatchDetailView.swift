import SwiftUI

struct MatchDetailView: View {

    @ObservedObject var store: AppStore

    let match: MatchResult
    let currentUserName: String

    @State private var showEditSheet = false

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

                        HStack(spacing: 4) {

                            Text(
                                match.teamAPlayers.joined(separator: "・")
                            )

                            if match.winner == "A" {

                                Text("👑")
                            }
                        }
                        .foregroundColor(
														.white
                        )

                        Text("vs")
                            .foregroundColor(.gray)

                        HStack(spacing: 4) {

                            Text(
                                match.teamBPlayers.joined(separator: "・")
                            )

                            if match.winner == "B" {

                                Text("👑")
                            }
                        }
                        .foregroundColor(
                            .white
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

                                Spacer()

																HStack(spacing: 8) {

																		HStack(spacing: 2) {

																				Text(score.teamAScore)

																				if
																						let a = Int(score.teamAScore),
																						let b = Int(score.teamBScore),
																						a > b {

																						Text("👑")
																				}
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

                // MARK: レート変動

                VStack(
                    alignment: .leading,
                    spacing: 12
                ) {

                    Text("レーティング変動")
                        .font(.headline)
                        .foregroundColor(.gray)

                    Text(
                        "\(match.winner == "A" ? "+" : "-")\(match.ratingDiff)"
                    )
                    .font(.system(size: 36, weight: .heavy))
                    .foregroundColor(
                        match.winner == "A"
                        ? .blue
                        : .red
                    )
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
        .navigationTitle("試合詳細")
        .navigationBarTitleDisplayMode(.inline)

        // MARK: 編集画面

        .sheet(isPresented: $showEditSheet) {

            MatchEditView(
                store: store,
                originalMatch: match
            )
        }

        // MARK: 編集ボタン

        .toolbar {

            if match.id == store.matchResults.first?.id {

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
}
