import Foundation
import SwiftData

@MainActor
struct SeedManager {
    static func seedDatabaseIfNeeded(context: ModelContext) {
        
        // 1. Seed Emotion Triggers
        let triggerFetch = FetchDescriptor<EmotionTrigger>()
        if (try? context.fetchCount(triggerFetch)) == 0 {
            let defaultTriggers = ["Stress", "Overthinking", "Imposter Syndrome"]
            for name in defaultTriggers {
                context.insert(EmotionTrigger(name: name, isDefault: true))
            }
        }
        
        // 2. Seed Content Packs
        let packFetch = FetchDescriptor<ContentPack>()
        if (try? context.fetchCount(packFetch)) == 0 {
            context.insert(ContentPack(id: "custom", title: "My Custom Notes", subtitle: "Your personal reframes.", isPurchased: true))
            context.insert(ContentPack(id: "core", title: "The Essentials", subtitle: "A foundational set of cognitive reframes.", isPurchased: true))
            context.insert(ContentPack(id: "pack.imposter", title: "Imposter Syndrome", subtitle: "Overcome the feeling of being a fraud.", isPurchased: true))
//            context.insert(ContentPack(id: "pack.stoic", title: "The Stoic Mind", subtitle: "Ancient wisdom.", isPurchased: false, isPremium: true))
//            context.insert(ContentPack(id: "pack.cbt", title: "CBT Reframes", subtitle: "Clinical perspectives.", isPurchased: false, isPremium: true))
            try? context.save()
        }
        
        // 3. Fetch the Packs to link them to messages
        let allPacks = (try? context.fetch(FetchDescriptor<ContentPack>())) ?? []
        let corePack = allPacks.first(where: { $0.id == "core" })
        let imposterPack = allPacks.first(where: { $0.id == "pack.imposter" })

        // 4. Seed Messages linked to their specific Pack Objects
        let messageFetch = FetchDescriptor<InterruptMessage>()
        if (try? context.fetchCount(messageFetch)) == 0 {
            guard let corePack else { return }

            // Build each group separately to keep the compiler happy
            let stress = StressMessages.createMessages(for: corePack)
            let selfTalk = SelfTalkMessages.createMessages(for: corePack)
            let saddness = SaddnessMessages.createMessages(for: corePack)
            let loneliness = LonelinessMessages.createMessages(for: corePack)
            let overthinking = OverthinkingMessages.createMessages(for: corePack)

            var masterLibrary: [InterruptMessage] = []
            masterLibrary.append(contentsOf: stress)
            masterLibrary.append(contentsOf: selfTalk)
            masterLibrary.append(contentsOf: saddness)
            masterLibrary.append(contentsOf: loneliness)
            masterLibrary.append(contentsOf: overthinking)

            if let imposterPack {
                let imposter = ImposterSyndromeMessages.createMessages(for: imposterPack)
                masterLibrary.append(contentsOf: imposter)
            }

            for message in masterLibrary {
                context.insert(message)
            }
            try? context.save()
        }
    }
}
