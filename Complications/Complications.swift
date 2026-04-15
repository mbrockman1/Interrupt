import WidgetKit
import SwiftUI
import AppIntents
import SwiftData

// MARK: - 1. Watch App Intent & Database Query

// Shared helper to load emotions from UserDefaults, SwiftData, or fallback defaults
struct EmotionLoader {
    static let appGroupID = "group.com.mbapps.interrupt"
    static let widgetKey = "WidgetEmotions"
    static let defaultEmotions = ["Stress", "Overthinking", "Imposter Syndrome"]
    
    static func loadEmotions() async -> [WatchEmotionEntity] {
        var entities = [WatchEmotionEntity(id: "Main Menu", name: "Main Menu (Ask Me)")]
        
        // 1. Try UserDefaults first (fastest, most reliable for widgets)
        if let defaults = UserDefaults(suiteName: appGroupID),
           let savedEmotions = defaults.stringArray(forKey: widgetKey),
           !savedEmotions.isEmpty {
            
            print("⌚️ Loaded \(savedEmotions.count) emotions from UserDefaults")
            entities.append(contentsOf: savedEmotions.map { WatchEmotionEntity(id: $0, name: $0) })
            return entities
        }
        
        // 2. Fallback to SwiftData
        do {
            let container = await DatabaseHelper.getContainer()
            let context = ModelContext(container)
            let fetchDescriptor = FetchDescriptor<EmotionTrigger>(sortBy: [SortDescriptor(\.name)])
            let triggers = try context.fetch(fetchDescriptor).filter { !$0.isHidden }
            
            if !triggers.isEmpty {
                print("⌚️ Loaded \(triggers.count) emotions from SwiftData")
                entities.append(contentsOf: triggers.map { WatchEmotionEntity(id: $0.name, name: $0.name) })
                return entities
            }
        } catch {
            print("⌚️ SwiftData error: \(error)")
        }
        
        // 3. Last resort: hardcoded defaults
        print("⌚️ Using hardcoded default emotions")
        entities.append(contentsOf: defaultEmotions.map { WatchEmotionEntity(id: $0, name: $0) })
        return entities
    }
}

struct WatchEmotionEntity: AppEntity {
    let id: String
    let name: String
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Emotion"
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(name)") }
    static var defaultQuery = WatchEmotionQuery()
}

struct WatchEmotionQuery: EntityQuery {
    // This is only used for Siri/Shortcuts to resolve emotion names
    func entities(for identifiers: [String]) async throws -> [WatchEmotionEntity] {
        return identifiers.map { WatchEmotionEntity(id: $0, name: $0) }
    }
    
    // NOTE: For widget configuration, WatchEmotionOptionsProvider is used instead
    func suggestedEntities() async throws -> [WatchEmotionEntity] {
        // Delegate to the options provider to avoid code duplication
        let provider = WatchEmotionOptionsProvider()
        return try await provider.results()
    }
    
    func defaultResult() async -> WatchEmotionEntity? {
        return WatchEmotionEntity(id: "Main Menu", name: "Main Menu (Ask Me)")
    }
}

struct WatchInterruptIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Select Emotion"
    static var description = IntentDescription("Choose an emotion to instantly interrupt.")
    
    @Parameter(title: "Target Emotion", optionsProvider: WatchEmotionOptionsProvider())
    var targetEmotion: WatchEmotionEntity?
}

struct WatchEmotionOptionsProvider: DynamicOptionsProvider {
    func results() async throws -> [WatchEmotionEntity] {
        return await EmotionLoader.loadEmotions()
    }
    
    func defaultResult() async -> WatchEmotionEntity? {
        return WatchEmotionEntity(id: "Main Menu", name: "Main Menu (Ask Me)")
    }
}

// MARK: - 2. Watch Provider
struct WatchProvider: AppIntentTimelineProvider {
    typealias Entry = WatchSimpleEntry
    typealias Intent = WatchInterruptIntent
    
    func placeholder(in context: Context) -> WatchSimpleEntry {
        WatchSimpleEntry(date: Date(), emotionName: "Main Menu")
    }
    
    func snapshot(for configuration: WatchInterruptIntent, in context: Context) async -> WatchSimpleEntry {
        WatchSimpleEntry(date: Date(), emotionName: configuration.targetEmotion?.id ?? "Main Menu")
    }
    
    func timeline(for configuration: WatchInterruptIntent, in context: Context) async -> Timeline<WatchSimpleEntry> {
        let entry = WatchSimpleEntry(date: Date(), emotionName: configuration.targetEmotion?.id ?? "Main Menu")
        return Timeline(entries:[entry], policy: .never)
    }
    
    func recommendations() -> [AppIntentRecommendation<WatchInterruptIntent>] {
        var recs: [AppIntentRecommendation<WatchInterruptIntent>] = []
        
        // Load emotions synchronously (UserDefaults access is fast)
        if let defaults = UserDefaults(suiteName: EmotionLoader.appGroupID),
           let savedEmotions = defaults.stringArray(forKey: EmotionLoader.widgetKey) {
            
            // Add up to 6 recommendations (Main Menu + 5 emotions)
            let defaultIntent = WatchInterruptIntent()
            recs.append(AppIntentRecommendation(intent: defaultIntent, description: "Main Menu (Ask Me)"))
            
            for emotionName in savedEmotions.prefix(5) {
                let intent = WatchInterruptIntent()
                intent.targetEmotion = WatchEmotionEntity(id: emotionName, name: emotionName)
                recs.append(AppIntentRecommendation(intent: intent, description: emotionName))
            }
        } else {
            // Fallback to default recommendation
            let defaultIntent = WatchInterruptIntent()
            recs.append(AppIntentRecommendation(intent: defaultIntent, description: "Main Menu (Ask Me)"))
        }
        
        return recs
    }
}

struct WatchSimpleEntry: TimelineEntry {
    let date: Date
    let emotionName: String
}

// MARK: - 3. Watch Complication UI
struct ComplicationsEntryView : View {
    var entry: WatchProvider.Entry
    @Environment(\.widgetFamily) var family

    var displayText: String { entry.emotionName == "Main Menu" ? "Interrupt" : entry.emotionName }
    
    var deepLinkURL: URL {
        let encoded = entry.emotionName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Main Menu"
        return URL(string: "interrupt://trigger?emotion=\(encoded)")!
    }
    
    var body: some View {
        Group {
            if family == .accessoryRectangular {
                // WIDE APPLE WATCH COMPLICATION
                HStack(spacing: 8) {
                    // FIXED: Restored the system hand icon!
                    Image(systemName: "hand.raised.fill")
                        .font(.title2)
                        .widgetAccentable()
                    
                    VStack(alignment: .leading) {
                        Text(displayText).font(.headline).widgetAccentable()
                        Text(entry.emotionName == "Main Menu" ? "Tap to reset" : "Instant Reset")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                // CIRCULAR COMPLICATION (Too small for text)
                // FIXED: Restored the system hand icon!
                Image(systemName: "hand.raised.fill")
                    .resizable()
                    .scaledToFit()
                    .padding(4)
                    .widgetAccentable()
            }
        }
        .widgetURL(deepLinkURL)
        .containerBackground(for: .widget) { Color.clear }
    }
}

struct Complications: Widget {
    let kind: String = "Complications"
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: WatchInterruptIntent.self, provider: WatchProvider()) { entry in
            ComplicationsEntryView(entry: entry)
        }
        .configurationDisplayName("Quick Interrupt")
        .description("Instantly break a rumination cycle.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular])
    }
}
