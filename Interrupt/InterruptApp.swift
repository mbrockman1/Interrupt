import SwiftUI
import SwiftData
import FirebaseCore
import FirebaseAnalytics
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
                .onAppear {
                    // Log app launch
                    Analytics.logEvent("app_launch", parameters: [
                        "version": Bundle.main.appVersion,
                        "build": Bundle.main.buildNumber
                    ])
                }
        }
        .modelContainer(sharedModelContainer)
    }
}

// MARK: - Bundle Extensions for Analytics
extension Bundle {
    var appVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
    }

    var buildNumber: String {
        infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
    }
}
