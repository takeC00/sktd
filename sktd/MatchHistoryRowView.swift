import SwiftUI

struct MatchHistoryRowView: View {

    let history: MatchResult
    let currentUserName: String
    let showOnlyOpponent: Bool

    var body: some View {

        HStack {

            VStack(
                alignment: .leading,
                spacing: 10
            ) {

                // MARK: 対戦カード

                HStack(spacing: 8) {

                    // チームA

                    HStack(spacing: 4) {

                        Text(
                            history.teamAPlayers.joined(separator: "・")
                        )

                        if history.winner == "A" {

                            Text("👑")
                        }
                    }
                    .foregroundColor(
                        history.winner == "A"
                        ? .blue
                        : .black
                    )

                    Text("vs")
                        .foregroundColor(.gray)

                    // チームB

                    HStack(spacing: 4) {

                        Text(
                            history.teamBPlayers.joined(separator: "・")
                        )

                        if history.winner == "B" {

                            Text("👑")
                        }
                    }
                    .foregroundColor(
                        history.winner == "B"
                        ? .blue
                        : .black
                    )
                }
                .font(.headline)

                // MARK: スコア

                HStack(spacing: 8) {

                    ForEach(history.setScores.indices, id: \.self) { index in

                        let score = history.setScores[index]

                        Text(
                            "\(score.teamAScore)-\(score.teamBScore)"
                        )
                        .font(.caption)
                        .foregroundColor(.gray)

                        if index != history.setScores.count - 1 {

                            Text("|")
                                .foregroundColor(.gray.opacity(0.5))
                        }
                    }
                }
            }

            Spacer()

            // MARK: 矢印

            Image(systemName: "chevron.right")
                .foregroundColor(.gray.opacity(0.7))
        }
        .padding()
        .background(

            RoundedRectangle(cornerRadius: 24)
                .fill(
                    Color.white.opacity(0.06)
                )
        )
        .overlay(

            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    Color.white.opacity(0.05),
                    lineWidth: 1
                )
        )
    }
}
