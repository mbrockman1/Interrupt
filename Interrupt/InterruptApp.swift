import SwiftUI
import SwiftData

@main
struct Interrupt_iOSApp: App {
    var sharedModelContainer: ModelContainer = DatabaseHelper.getContainer()

    var body: some Scene {
        WindowGroup {
            iOSContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
