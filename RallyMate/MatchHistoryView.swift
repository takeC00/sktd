import SwiftUI

struct MatchHistoryView: View {

    @ObservedObject var store: AppStore

    var currentCircleHistories: [MatchResult] {
        store.matchResults.sorted { $0.date > $1.date }
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
                            currentUserName: store.currentUserId
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                store.startListeningMatches()
            }
        }
    }
}
