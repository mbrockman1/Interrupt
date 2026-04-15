import SwiftUI
import SwiftData

struct iOSContentView: View {
    @Environment(\.modelContext) private var context
    @State private var selectedTab = 0
    
    // NEW: Holds the deep-linked emotion to pass to the child view
    @State private var pendingEmotion: String? = nil
    
    @AppStorage("appFontPreference") private var appFontRaw: String = AppFontDesign.rounded.rawValue
    private var currentFontDesign: Font.Design {
        AppFontDesign(rawValue: appFontRaw)?.design ?? .rounded
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            // Pass the binding down!
            InterruptView(pendingEmotion: $pendingEmotion)
                .tabItem { Label("Interrupt", systemImage: "hand.raised.fill") }
                .tag(0)
            
            AnalyticsView()
                .tabItem { Label("Insights", systemImage: "chart.bar.fill") }
                .tag(1)
            
            ContentLibraryView()
                .tabItem { Label("Library", systemImage: "books.vertical.fill") }
                .tag(2)
            
            SettingsView()
                .tabItem { Label("Info", systemImage: "info.circle.fill") }
                .tag(3)
        }
        .fontDesign(currentFontDesign)
        .task {
            WatchSyncManager.shared.modelContext = context
            WatchSyncManager.shared.startSession()
            
            try? await Task.sleep(for: .milliseconds(150))
            forceSyncAllData()
            await SeedManager.seedDatabaseIfNeeded(context: context)
        }
        // ONLY ONE onOpenURL IN THE APP
        .onOpenURL { url in
            guard url.scheme == "interrupt" && url.host == "trigger" else { return }
            
            // 1. Force the app to switch to the main tab
            selectedTab = 0
            
            // 2. Parse the emotion
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let emotionItem = components.queryItems?.first(where: { $0.name == "emotion" }),
               let emotionName = emotionItem.value,
               emotionName != "Main Menu" {
                
                // 3. Hand the emotion to InterruptView to deal with it
                pendingEmotion = emotionName
            }
        }
    }
    
    private func forceSyncAllData() {
        let fetchMessages = FetchDescriptor<InterruptMessage>()
        let fetchTriggers = FetchDescriptor<EmotionTrigger>()
        
        if let messages = try? context.fetch(fetchMessages) {
            WatchSyncManager.shared.syncLibraryToWatch(messages: messages)
        }
        
        if let triggers = try? context.fetch(fetchTriggers) {
            WatchSyncManager.shared.syncTriggersToWatch(triggers: triggers)
        }
        print("🔄 iPhone: Force-syncing all data to Watch.")
    }
}
