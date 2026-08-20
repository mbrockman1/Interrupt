import SwiftUI
import SwiftData
import FirebaseCore
import FirebaseCrashlytics

@main
struct Interrupt_iOSApp: App {
    var sharedModelContainer: ModelContainer = DatabaseHelper.getContainer()

    init() {
        // Initialize Firebase
        FirebaseApp.configure()

        // Enable Crashlytics collection
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
    }

    var body: some Scene {
        WindowGroup {
            iOSContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
