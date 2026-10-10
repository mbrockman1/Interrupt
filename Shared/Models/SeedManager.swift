import Foundation
import SwiftData

@MainActor
struct SeedManager {
    static func seedDatabaseIfNeeded(context: ModelContext) {

        let triggerFetch = FetchDescriptor<EmotionTrigger>()
        if (try? context.fetchCount(triggerFetch)) == 0 {
            let defaultTriggers = ["Stress", "Overthinking", "Imposter Syndrome"]
            for name in defaultTriggers {
                context.insert(EmotionTrigger(name: name, isDefault: true))
            }
        }

        // Packs are ensured one by one so new packs reach existing installs too.
        let packs: [(pack: ContentPack, messages: (ContentPack) -> [InterruptMessage])] = [
            (ContentPack(id: "custom", title: "My Custom Notes", subtitle: "Your personal reframes.", isPurchased: true), { _ in [] }),
            (ContentPack(id: "received", title: "Received Notes", subtitle: "Notes shared by friends.", isPurchased: true), { _ in [] }),
            (ContentPack(id: "core", title: "The Essentials", subtitle: "A foundational set of cognitive reframes.", isPurchased: true),
             { StressMessages.createMessages(for: $0) + OverthinkingMessages.createMessages(for: $0) }),
            (ContentPack(id: "pack.imposter", title: "Imposter Syndrome", subtitle: "Overcome the feeling of being a fraud.", isPurchased: true),
             { ImposterSyndromeMessages.createMessages(for: $0) }),
            (ContentPack(id: "pack.stoic", title: "The Stoic Mind", subtitle: "Ancient wisdom for modern anxiety.", isPurchased: false, isPremium: true),
             { StoicMessages.createMessages(for: $0) }),
            (ContentPack(id: ScienceFactsMessages.packID, title: "Science Facts", subtitle: "Real science to calm a racing mind. Free.", isPurchased: false, isPremium: false),
             { ScienceFactsMessages.createMessages(for: $0) }),
            (ContentPack(id: ScientistsMessages.packID, title: "Words of Scientists", subtitle: "Curiosity and courage from great scientists. Free.", isPurchased: false, isPremium: false),
             { ScientistsMessages.createMessages(for: $0) }),
            (ContentPack(id: WomenScientistsMessages.packID, title: "Women in Science", subtitle: "Wisdom from pioneering female scientists.", isPurchased: false, isPremium: true),
             { WomenScientistsMessages.createMessages(for: $0) })
        ]

        let existingPacks = (try? context.fetch(FetchDescriptor<ContentPack>())) ?? []
        let existingMessages = (try? context.fetch(FetchDescriptor<InterruptMessage>())) ?? []

        for entry in packs {
            let pack = existingPacks.first(where: { $0.id == entry.pack.id }) ?? {
                context.insert(entry.pack)
                return entry.pack
            }()

            if !existingMessages.contains(where: { $0.packID == pack.id }) {
                for message in entry.messages(pack) { context.insert(message) }
            }
        }

        // Locked packs must never serve quotes, including ones seeded by older versions.
        for message in existingMessages where message.isActive {
            if let pack = existingPacks.first(where: { $0.id == message.packID }), !pack.isPurchased {
                message.isActive = false
            }
        }

        try? context.save()
    }
}
