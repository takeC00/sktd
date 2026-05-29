import SwiftUI
import FirebaseCore

@main
struct RallyMateApp: App {

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
