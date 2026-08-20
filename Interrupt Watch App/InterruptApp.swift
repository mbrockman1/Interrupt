import SwiftUI
import SwiftData
#if FIREBASE_ENABLED
import FirebaseCore
import FirebaseAnalytics
#endif

@main
struct Interrupt_WatchApp: App {
    var sharedModelContainer: ModelContainer = DatabaseHelper.getContainer()

    init() {
        // Initialize Firebase (only active once linked to this target)
        #if FIREBASE_ENABLED
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
                    #if FIREBASE_ENABLED
                    Analytics.logEvent("watch_app_launch", parameters: [
                        "device": "apple_watch"
                    ])
                    #endif
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
