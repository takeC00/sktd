import SwiftUI

struct ContentView: View {

    @StateObject private var authManager =
        FirebaseAuthManager.shared

    var body: some View {

        Group {

            // 未ログイン

            if !authManager.isLoggedIn {

                LoginView()
            }

            // メイン

            else {

                MainTabView()
            }
        }
    }
}
