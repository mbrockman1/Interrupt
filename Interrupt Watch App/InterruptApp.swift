import SwiftUI
import SwiftData
#if canImport(FirebaseCore)
import FirebaseCore
import FirebaseAnalytics
#endif

@main
struct Interrupt_WatchApp: App {
    var sharedModelContainer: ModelContainer = DatabaseHelper.getContainer()

    init() {
        // Initialize Firebase (only active once linked to this target)
        #if canImport(FirebaseCore)
        FirebaseApp.configure()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            WatchContentView()
                .onAppear {
                    // Start the instant sync session
                    WatchSyncManager.shared.startSession()

                    // Log watch app launch
                    #if canImport(FirebaseAnalytics)
                    Analytics.logEvent("watch_app_launch", parameters: [
                        "device": "apple_watch"
                    ])
                    #endif
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
