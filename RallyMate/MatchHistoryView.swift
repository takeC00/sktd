import SwiftUI

struct MatchHistoryView: View {

    @ObservedObject var store: AppStore
    @StateObject private var authManager = FirebaseAuthManager.shared
    @State private var showAccountSettings = false

    var currentCircleHistories: [MatchResult] {
        store.matchesForCurrentCircle.sorted { $0.date > $1.date }
    }

    private var currentCircleName: String? {
        guard let circleId = authManager.currentCircleId else { return nil }
        return authManager.joinedCircles.first { $0.id == circleId }?.name
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

            Group {
                if authManager.currentCircleId == nil {
                    ContentUnavailableView(
                        "サークルが選択されていません",
                        systemImage: "person.3",
                        description: Text("Circle タブからサークルを選択してください")
                    )
                } else if store.isLoadingMatches && currentCircleHistories.isEmpty {
                    ProgressView("読み込み中...")
                } else if currentCircleHistories.isEmpty {
                    ContentUnavailableView(
                        "試合履歴がありません",
                        systemImage: "clock.arrow.circlepath",
                        description: Text("Input タブから試合結果を登録してください")
                    )
                } else {
                    ScrollView {
                        LazyVStack(
                            alignment: .leading,
                            spacing: 28
                        ) {
                            if let circleName = currentCircleName {
                                Text(circleName)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.orange)
                                    .padding(.top, 4)
                            }

                            ForEach(sortedDates, id: \.self) { date in
                                MatchHistoryDateSection(
                                    store: store,
                                    date: date,
                                    histories: groupedHistories[date] ?? []
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 12)
                        .padding(.bottom, 120)
                    }
                }
            }
            .background(
                Color.black.ignoresSafeArea()
            )
            .foregroundStyle(.white)
            .tint(.white)

            .navigationTitle("試合履歴")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .accountToolbar(showAccountSettings: $showAccountSettings)
            .accountSettingsSheet(isPresented: $showAccountSettings)
            .onAppear {
                store.startListeningMatches()
            }
            .onChange(of: authManager.currentCircleId) { _, _ in
                store.startListeningMatches()
            }
        }
    }
}
