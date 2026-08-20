import SwiftUI
import SwiftData

@main
struct Interrupt_WatchApp: App {
    var sharedModelContainer: ModelContainer = DatabaseHelper.getContainer()

    var body: some Scene {
        WindowGroup {
            WatchContentView()
                .onAppear {
                    // Start the instant sync session
                    WatchSyncManager.shared.startSession()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
