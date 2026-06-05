import SwiftUI
import FirebaseCore

@main
struct RallyMateApp: App {

    init() {
        RallyAppearance.configure()
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
        }
    }
}
