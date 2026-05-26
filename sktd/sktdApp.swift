import SwiftUI
import FirebaseCore

@main
struct sktdApp: App {

    init() {

        FirebaseApp.configure()
    }

    var body: some Scene {

        WindowGroup {

            ContentView()
        }
    }
}
