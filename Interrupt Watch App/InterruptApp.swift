import SwiftUI
import SwiftData
import FirebaseCore
import FirebaseAnalytics

@main
struct Interrupt_WatchApp: App {
    var sharedModelContainer: ModelContainer = DatabaseHelper.getContainer()

    init() {
        // Initialize Firebase
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            WatchContentView()
                .onAppear {
                    // Start the instant sync session
                    WatchSyncManager.shared.startSession()

                    // Log watch app launch
                    Analytics.logEvent("watch_app_launch", parameters: [
                        "device": "apple_watch"
                    ])
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
