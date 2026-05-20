import SwiftUI

struct ContentView: View {

    @StateObject private var store = AppStore()

    @State private var selectedTab = 0

    @State private var isLoggedIn = false

    var body: some View {

        if isLoggedIn {

            TabView(selection: $selectedTab) {

                TopView(store: store)
                    .tabItem {
                        Label("TOP", systemImage: "house")
                    }
                    .tag(0)

                MatchInputView(
                    store: store,
                    onRegistered: {
                        selectedTab = 0
                    }
                )
                .tabItem {
                    Label("試合入力", systemImage: "plus.circle")
                }
                .tag(1)

                MatchHistoryView(store: store)
                    .tabItem {
                        Label("履歴", systemImage: "clock")
                    }
                    .tag(2)

                RankingView(store: store)
                    .tabItem {
                        Label("ランキング", systemImage: "crown")
                    }
                    .tag(3)

								CircleSwitchView(store: store)
										.tabItem {
												Label("サークル", systemImage: "person.3")
										}
										.tag(4)
            }

        } else {

            LoginView {
                isLoggedIn = true
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {

    static var previews: some View {

        ContentView()
    }
}
