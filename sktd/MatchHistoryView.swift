import SwiftUI

struct MatchHistoryView: View {

    @ObservedObject var store: AppStore

    @State private var editingMatch: MatchResult?

    // MARK: 現在のサークル履歴

    var currentCircleHistories: [MatchResult] {

        store.matchResults
            .filter {
                $0.circleId == store.currentCircleId
            }
            .sorted {
                $0.date > $1.date
            }
    }

    // MARK: 日付ごと

    var groupedHistories: [String: [MatchResult]] {

        Dictionary(grouping: currentCircleHistories) {
            formatOnlyDate($0.date)
        }
    }

    // MARK: 日付ソート

    var sortedDates: [String] {

        groupedHistories.keys.sorted(by: >)
    }

    var body: some View {

        NavigationStack {

            ScrollView {

                LazyVStack(
                    alignment: .leading,
                    spacing: 28
                ) {

                    ForEach(sortedDates, id: \.self) { date in

                        MatchHistoryDateSection(
                            store: store,
                            date: date,
                            histories: groupedHistories[date] ?? [],
                            currentUserName: store.currentUserName
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 120)
            }
            .background(
                Color.black.ignoresSafeArea()
            )

            .navigationTitle("試合履歴")
            .navigationBarTitleDisplayMode(.large)

            .sheet(item: $editingMatch) { match in

                MatchEditView(
                    store: store,
                    originalMatch: match
                )
            }
        }
    }

    // MARK: 日付変換

    func formatOnlyDate(_ date: Date) -> String {

        let formatter = DateFormatter()

        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy/MM/dd"

        return formatter.string(from: date)
    }
}
