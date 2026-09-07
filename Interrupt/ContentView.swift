import SwiftUI
import SwiftData

struct iOSContentView: View {
    @Environment(\.modelContext) private var context
    @State private var selectedTab = 0
    
    @State private var incomingPayload: SharedMessagePayload? = nil
    @State private var showingImportAlert = false
    
    // NEW: Holds the deep-linked emotion to pass to the child view
    @State private var pendingEmotion: String? = nil
    
    @AppStorage("appFontPreference") private var appFontRaw: String = AppFontDesign.rounded.rawValue
    private var currentFontDesign: Font.Design {
        AppFontDesign(rawValue: appFontRaw)?.design ?? .rounded
    }
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
        @State private var forceShowOnboarding = false

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
            SeedManager.seedDatabaseIfNeeded(context: context)

            // Re-unlock any packs the user already owns (reinstall, new device, etc.)
            await StoreManager.shared.updatePurchasedStatus(context: context)
        }
        // ONLY ONE onOpenURL IN THE APP
        .onOpenURL { url in
                    guard url.scheme == "interrupt" else { return }
                    
                    // --- 1. HANDLE WIDGET TRIGGER ---
                    if url.host == "trigger" {
                        selectedTab = 0
                        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                           let emotionItem = components.queryItems?.first(where: { $0.name == "emotion" }),
                           let emotionName = emotionItem.value, emotionName != "Main Menu" {
                            pendingEmotion = emotionName
                        }
                    }
                    
                    // --- 2. NEW: HANDLE iMESSAGE IMPORT ---
                    if url.host == "import" {
                        if let payload = ShareHelper.decode(from: url) {
                            // Trigger the alert so the user can preview it before saving
                            incomingPayload = payload
                            showingImportAlert = true
                        }
                    }
                }
                .fullScreenCover(isPresented: Binding(
                    get: { !hasSeenOnboarding || forceShowOnboarding },
                    set: { _ in forceShowOnboarding = false }
                )) {
                    OnboardingView()
                        // Ensures the onboarding screen uses your selected friendly font!
                        .fontDesign(currentFontDesign)
                }
                // --- 3. NEW: BEAUTIFUL IMPORT SHEET ---
                .sheet(item: $incomingPayload) { payload in
                    VStack(spacing: 24) {
                        Image(systemName: "envelope.open.fill")
                            .font(.system(size: 46))
                            .foregroundStyle(Color.accentColor.gradient)
                            .padding(.top, 20)
                        
                        VStack(spacing: 12) {
                            Text("A Note for \(payload.categoryName)")
                                .font(.title2.bold())
                            
                            Text("\"\(payload.text)\"")
                                .font(.body)
                                .italic()
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 24)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 16) {
                            Button(action: { incomingPayload = nil }) {
                                Text("Decline")
                                    .fontWeight(.medium)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.secondary.opacity(0.15))
                                    .foregroundStyle(.primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                            
                            Button(action: {
                                acceptSharedNote(payload)
                                incomingPayload = nil
                            }) {
                                Text("Save to Library")
                                    .fontWeight(.bold)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.accentColor.gradient)
                                    .foregroundStyle(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                    .presentationDetents([.fraction(0.45)]) // Makes it a beautiful half-screen card
                    .presentationCornerRadius(30)
                }
    }
    
    // MARK: - Import Logic
    private func acceptSharedNote(_ payload: SharedMessagePayload) {
        // 1. Check if "Received Notes" pack exists, if not, create it dynamically!
        let packFetch = FetchDescriptor<ContentPack>(predicate: #Predicate { $0.id == "received" })
        if (try? context.fetchCount(packFetch)) == 0 {
            context.insert(ContentPack(id: "received", title: "Received Notes", subtitle: "Notes shared by friends.", isPurchased: true))
        }
        
        // 2. Save the new message to the Received pack
        let newMessage = InterruptMessage(
            text: payload.text,
            typeRaw: payload.typeRaw,
            categoryName: payload.categoryName,
            packID: "received"
        )
        context.insert(newMessage)
        try? context.save()
        
        // 3. Sync to Watch
        forceSyncAllData()
        
        // 4. Switch to the Library tab so they can see it!
        selectedTab = 2
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
