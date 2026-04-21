import SwiftUI
import SwiftData

struct WatchContentView: View {
    @Environment(\.modelContext) private var context
    
    // NEW: Dynamically fetch the emotions from the database
    @Query(sort: \EmotionTrigger.name) private var triggers: [EmotionTrigger]
    
    @State private var activeMessage: InterruptMessage?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 8) {
                    Text("What are you feeling?")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 4)
                        .padding(.horizontal)
                    
                    // FIXED HERE: Loop through dynamic triggers instead of the old enum
                    ForEach(triggers.filter { !$0.isHidden }) { trigger in
                        Button(action: {
                            triggerInterrupt(for: trigger.name)
                        }) {
                            Text(trigger.name)
                                .font(.body)
                                .fontWeight(.medium)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 12)
                                .padding(.horizontal)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.accentColor.opacity(0.25))
                        .foregroundStyle(.white)
                    }                }
                .padding(.horizontal, 8)
            }
            .navigationTitle("Interrupt")
            .navigationBarTitleDisplayMode(.inline)
            .fullScreenCover(item: $activeMessage) { message in
                WatchMessageCardView(message: message)
            }
            .task {
                SeedManager.seedDatabaseIfNeeded(context: context)
                WatchSyncManager.shared.modelContext = context
                WatchSyncManager.shared.startSession()
                
                // Save the list for the widget right when the app opens
                updateWidgetList()
            }
            // Instantly update the widget list anytime the database changes!
            .onChange(of: triggers) { _, _ in
                updateWidgetList()
            }        }
        .onAppear {
            SeedManager.seedDatabaseIfNeeded(context: context)
        }
        .onOpenURL { url in
                    guard url.scheme == "interrupt" && url.host == "trigger" else { return }
                    
                    if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                       let emotionItem = components.queryItems?.first(where: { $0.name == "emotion" }),
                       let emotionName = emotionItem.value,
                       emotionName != "Main Menu" {
                        
                        // SAFETY CHECK: Does this emotion still exist and is it active?
                        let fetch = FetchDescriptor<EmotionTrigger>()
                        if let allTriggers = try? context.fetch(fetch),
                           allTriggers.contains(where: { $0.name == emotionName && !$0.isHidden }) {
                            
                            // Emotion exists! Trigger it instantly.
                            triggerInterrupt(for: emotionName)
                        } else {
                            // Emotion was deleted/hidden. Do nothing, just leave them on the Main Menu.
                            print("⚠️ Deep link emotion '\(emotionName)' was deleted or hidden. Defaulting to Main Menu.")
                        }
                    }
                }
    }
    
    // FIXED HERE: Pass String instead of EmotionCategory
    private func triggerInterrupt(for categoryName: String) {
        // 1. Haptics
        WKInterfaceDevice.current().play(.click)
        
        // 2. Log Locally on the Watch (Backup)
        let newLog = InterruptLog(categoryName: categoryName)
        context.insert(newLog)
        try? context.save()
        
        // 3. THE FIX: SEND TO IPHONE INSTANTLY
        // This tells the SyncManager to beam the log over Bluetooth/Wi-Fi
        WatchSyncManager.shared.sendLogToPhone(categoryName: categoryName)
        
        // 4. Show the message
        let message = MessageStore.shared.getMessage(for: categoryName, context: context)
        
        // CHECK SETTINGS
        activeMessage = message
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            WKInterfaceDevice.current().play(.success)
        }
    }

    
    private func updateWidgetList() {
            // Grab only the active names
            let activeNames = triggers.filter { !$0.isHidden }.map { $0.name }
            
            // Save them to the shared App Group UserDefaults
            if let defaults = UserDefaults(suiteName: "group.com.mbapps.interrupt") {
                defaults.set(activeNames, forKey: "WidgetEmotions")
                print("⌚️ Saved \(activeNames.count) emotions to UserDefaults for the Complication!")
            }
        }
    
}

