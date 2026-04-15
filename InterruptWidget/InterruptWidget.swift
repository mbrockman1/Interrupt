import WidgetKit
import SwiftUI
import AppIntents
import SwiftData

// MARK: - 1. iOS App Intent & Database Query
struct EmotionEntity: AppEntity {
    let id: String
    let name: String
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Emotion"
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(name)") }
    static var defaultQuery = EmotionQuery()
}

struct EmotionQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [EmotionEntity] {
        return identifiers.map { EmotionEntity(id: $0, name: $0) }
    }
    
    func suggestedEntities() async throws -> [EmotionEntity] {
        let fetchedEntities: [EmotionEntity] = await MainActor.run {
            var entities = [EmotionEntity(id: "Main Menu", name: "Main Menu (Ask Me)")]
            
            do {
                let container = DatabaseHelper.getContainer()
                let context = ModelContext(container)
                
                let fetchDescriptor = FetchDescriptor<EmotionTrigger>(sortBy: [SortDescriptor(\.name)])
                let triggers = try context.fetch(fetchDescriptor)
                
                let activeTriggers = triggers.filter { !$0.isHidden }
                
                if !activeTriggers.isEmpty {
                    for trigger in activeTriggers {
                        entities.append(EmotionEntity(id: trigger.name, name: trigger.name))
                    }
                    return entities
                }
            } catch {
                print("📱 Widget DB locked or empty: \(error)")
            }
            
            // FAILSAFE
            let defaultFailsafes = ["Stress", "Overthinking", "Imposter Syndrome"]
            for fallback in defaultFailsafes {
                entities.append(EmotionEntity(id: fallback, name: fallback))
            }
            
            return entities
        }
        
        return fetchedEntities
    }
    
    func defaultResult() async -> EmotionEntity? {
        return EmotionEntity(id: "Main Menu", name: "Main Menu (Ask Me)")
    }
}

struct InterruptIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Select Emotion"
    static var description = IntentDescription("Choose an emotion to instantly interrupt.")
    @Parameter(title: "Target Emotion") var targetEmotion: EmotionEntity?
}

// MARK: - 2. iOS Widget Provider
struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry { SimpleEntry(date: Date(), emotionName: "Main Menu") }
    func snapshot(for configuration: InterruptIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), emotionName: configuration.targetEmotion?.id ?? "Main Menu")
    }
    func timeline(for configuration: InterruptIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let entry = SimpleEntry(date: Date(), emotionName: configuration.targetEmotion?.id ?? "Main Menu")
        return Timeline(entries: [entry], policy: .never)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let emotionName: String
}

// MARK: - 3. iOS Widget UI
struct InterruptWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var displayText: String { entry.emotionName == "Main Menu" ? "Interrupt" : entry.emotionName }
    
    var deepLinkURL: URL {
        let encoded = entry.emotionName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Main Menu"
        return URL(string: "interrupt://trigger?emotion=\(encoded)")!
    }

    var body: some View {
        Group {
            if family == .systemSmall {
                // iPhone Home Screen
                VStack(spacing: 8) {
                    Image(systemName: "hand.raised.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.white)
                    Text(displayText)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .widgetURL(deepLinkURL)
                .containerBackground(for: .widget) { Rectangle().fill(Color.accentColor.gradient) }
                
            } else {
                // iPhone Lock Screen
                HStack(spacing: 8) {
                    Image(systemName: "hand.raised.fill")
                        .font(.system(size: 36))
                        .widgetAccentable()
                    if family == .accessoryRectangular {
                        VStack(alignment: .leading) {
                            Text(displayText).font(.headline).widgetAccentable()
                            Text(entry.emotionName == "Main Menu" ? "Tap to reset" : "Instant Reset").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                .widgetURL(deepLinkURL)
                .containerBackground(for: .widget) { Color.clear }
            }
        }
    }
}

@main
struct InterruptWidget: Widget {
    let kind: String = "InterruptWidget"
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: InterruptIntent.self, provider: Provider()) { entry in
            InterruptWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Quick Interrupt")
        .description("Instantly break a rumination cycle.")
        .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryRectangular])
    }
}

