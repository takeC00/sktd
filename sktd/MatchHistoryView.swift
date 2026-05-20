import SwiftUI

struct MatchHistoryView: View {

    @ObservedObject var store: AppStore

    var currentCircleHistories: [MatchResult] {
        store.matchResults.filter {
            $0.circleId == store.currentCircleId
        }
    }

    var groupedHistories: [String: [MatchResult]] {
        Dictionary(grouping: currentCircleHistories) {
            formatOnlyDate($0.date)
        }
    }

    var sortedDates: [String] {
        groupedHistories.keys.sorted(by: >)
    }

    var body: some View {
        NavigationView {
            List {
                if currentCircleHistories.isEmpty {
                    Text("まだ試合履歴がありません")
                        .foregroundColor(.gray)
                } else {
                    ForEach(sortedDates, id: \.self) { date in
                        MatchHistoryDateSection(
                            date: date,
                            histories: groupedHistories[date] ?? []
                        )
                    }
                }
            }
            .navigationTitle("試合履歴")
        }
    }
}

struct MatchHistoryDateSection: View {

    let date: String
    let histories: [MatchResult]

    var body: some View {
        Section(header: Text(date)) {
            ForEach(histories) { history in
                NavigationLink(
                    destination: MatchDetailView(match: history)
                ) {
                    MatchHistoryRowView(history: history)
                }
            }
        }
    }
}

struct MatchHistoryRowView: View {

    let history: MatchResult

    var opponentText: String {
        history.teamBPlayers.joined(separator: " / ")
    }

    var resultText: String {
        history.winner == "A" ? "勝利" : "敗北"
    }

    var ratingDiffText: String {
        history.ratingDiff > 0 ? "+\(history.ratingDiff)" : "\(history.ratingDiff)"
    }

    var ratingDiffColor: Color {
        history.ratingDiff > 0 ? .green : .red
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("vs \(opponentText)")
                    .font(.headline)

                Text(resultText)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            Text(ratingDiffText)
                .font(.headline)
                .foregroundColor(ratingDiffColor)
        }
        .padding(.vertical, 6)
    }
}
