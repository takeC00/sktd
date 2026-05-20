import SwiftUI

struct MatchDetailView: View {

    let match: MatchResult
    let currentUserName: String

    var teamADiff: Int {
        match.winner == "A" ? match.ratingDiff : -match.ratingDiff
    }

    var teamBDiff: Int {
        match.winner == "B" ? match.ratingDiff : -match.ratingDiff
    }

    func diffText(_ diff: Int) -> String {
        diff > 0 ? "+\(diff)" : "\(diff)"
    }

    func diffColor(_ diff: Int) -> Color {
        diff >= 0 ? .green : .red
    }

    var body: some View {
        List {
            Section(header: Text("試合情報")) {
                HStack {
                    Text("試合形式")
                    Spacer()
                    Text(match.matchType.rawValue)
                }

                HStack {
                    Text("日付")
                    Spacer()
                    Text(formatDate(match.date))
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
            }

            Section(header: Text("チームA")) {
                ForEach(match.teamAPlayers, id: \.self) { player in
                    HStack {
                        Text(player)
                        Spacer()
                        Text(diffText(teamADiff))
                            .foregroundColor(diffColor(teamADiff))
                            .bold()
                    }
                }
            }

            Section(header: Text("チームB")) {
                ForEach(match.teamBPlayers, id: \.self) { player in
                    HStack {
                        Text(player)
                        Spacer()
                        Text(diffText(teamBDiff))
                            .foregroundColor(diffColor(teamBDiff))
                            .bold()
                    }
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
