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
        var packs: [(pack: ContentPack, messages: (ContentPack) -> [InterruptMessage])] = [
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
        for catalog in InspirationPacks.all {
            packs.append((pack: catalog.makePack(), messages: { catalog.createMessages(for: $0) }))
        }

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

        migrateLegacyEmotionTags(context: context)

        // Locked packs must never serve quotes, including ones seeded by older versions.
        let allPacks = (try? context.fetch(FetchDescriptor<ContentPack>())) ?? []
        let allMessages = (try? context.fetch(FetchDescriptor<InterruptMessage>())) ?? []
        for message in allMessages where message.isActive {
            if let pack = allPacks.first(where: { $0.id == message.packID }), !pack.isPurchased {
                message.isActive = false
            }
        }

        try? context.save()
    }

    // Older versions shipped pack quotes with a fixed emotion each. Packs now carry no emotions of
    // their own, so fold those tags into a pack-level assignment: owners keep hearing the pack for the
    // same emotions, and packs they never unlocked simply become unassigned. Runs only on legacy data
    // (a message in an assignable pack that still has a real emotion tag), so repeat calls are no-ops.
    static func migrateLegacyEmotionTags(context: ModelContext) {
        let packs = (try? context.fetch(FetchDescriptor<ContentPack>())) ?? []
        let messages = (try? context.fetch(FetchDescriptor<InterruptMessage>())) ?? []

        for pack in packs where pack.usesEmotionAssignment {
            let packMessages = messages.filter { $0.packID == pack.id }
            let legacy = packMessages.filter { $0.categoryName != InterruptMessage.unlinkedCategory }
            guard !legacy.isEmpty else { continue }

            let carried = pack.isPurchased ? Array(Set(legacy.map(\.categoryName))).sorted() : []
            for message in packMessages {
                message.assignedEmotions = carried
                message.categoryName = InterruptMessage.unlinkedCategory
            }
        }
    }
}
