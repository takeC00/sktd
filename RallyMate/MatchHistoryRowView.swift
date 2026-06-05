import SwiftUI

struct MatchHistoryRowView: View {

    let history: MatchResult
    let store: AppStore
    let currentUserId: String
    let showOnlyOpponent: Bool

    var body: some View {

        HStack {

            VStack(
                alignment: .leading,
                spacing: 10
            ) {

                HStack(spacing: 8) {

                    teamLabel(
                        players: history.teamAPlayers,
                        isWinner: history.winner == "A"
                    )

                    Text("vs")
                        .foregroundStyle(.gray)

                    teamLabel(
                        players: history.teamBPlayers,
                        isWinner: history.winner == "B"
                    )
                }
                .font(.headline)

                HStack(spacing: 8) {

                    ForEach(history.setScores.indices, id: \.self) { index in

                        let score = history.setScores[index]

                        Text(
                            "\(score.teamAScore)-\(score.teamBScore)"
                        )
                        .font(.caption)
                        .foregroundStyle(.gray)

                        if index != history.setScores.count - 1 {

                            Text("|")
                                .foregroundStyle(.gray.opacity(0.5))
                        }
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(.gray.opacity(0.7))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
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
