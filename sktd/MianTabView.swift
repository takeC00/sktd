import SwiftUI

struct MainTabView: View {

    @StateObject private var store =
        AppStore()

    @StateObject private var authManager =
        FirebaseAuthManager.shared

    private enum Tab: Hashable {
        case home
        case matchInput
        case matchHistory
        case ranking
        case circle
    }

    @State private var selectedTab: Tab = .home

    var body: some View {

        TabView(selection: $selectedTab) {

            // MARK: Home

            TopView(store: store)
                .tabItem {

                    Image(
                        systemName: "chart.line.uptrend.xyaxis"
                    )

                    Text("Rating")
                }
                .tag(Tab.home)

            // MARK: Match Input

            MatchInputView(store: store) {
                selectedTab = .matchHistory
            }
            .tabItem {
                Image(systemName: "square.and.pencil")
                Text("Input")
            }
            .tag(Tab.matchInput)

            // MARK: Match History

            MatchHistoryView(store: store)
                .tabItem {
                    Image(systemName: "clock.arrow.circlepath")
                    Text("History")
                }
                .tag(Tab.matchHistory)

            // MARK: Ranking

            RankingView(store: store)
                .tabItem {

                    Image(
                        systemName:
                            "chart.bar.fill"
                    )

                    Text("Ranking")
                }
                .tag(Tab.ranking)

            // MARK: Circle

            CircleSwitchView(store: store)
                .tabItem {
                    Image(systemName: "person.3.fill")
                    Text("Circle")
                }
                .tag(Tab.circle)
        }
        .tint(.orange)
        .onAppear {
            authManager.refreshCircles()
            store.loadMatches()
        }
        .onChange(of: authManager.currentCircleId) { _, _ in
            store.loadMatches()
        }
    }
}
