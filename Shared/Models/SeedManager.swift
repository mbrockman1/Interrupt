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
        
        let packFetch = FetchDescriptor<ContentPack>()
        if (try? context.fetchCount(packFetch)) == 0 {
            context.insert(ContentPack(id: "custom", title: "My Custom Notes", subtitle: "Your personal reframes.", isPurchased: true))
            context.insert(ContentPack(id: "received", title: "Received Notes", subtitle: "Notes shared by friends.", isPurchased: true))
            context.insert(ContentPack(id: "core", title: "The Essentials", subtitle: "A foundational set of cognitive reframes.", isPurchased: true))
            context.insert(ContentPack(id: "pack.imposter", title: "Imposter Syndrome", subtitle: "Overcome the feeling of being a fraud.", isPurchased: true))
            
            // The Premium Pack (Locked)
            context.insert(ContentPack(id: "pack.stoic", title: "The Stoic Mind", subtitle: "Ancient wisdom for modern anxiety.", isPurchased: false, isPremium: true))
            try? context.save()
        }
        
        let allPacks = (try? context.fetch(FetchDescriptor<ContentPack>())) ?? []
        let corePack = allPacks.first(where: { $0.id == "core" })
        let imposterPack = allPacks.first(where: { $0.id == "pack.imposter" })
        let stoicPack = allPacks.first(where: { $0.id == "pack.stoic" }) // Fetch the Stoic Pack object
        
        let messageFetch = FetchDescriptor<InterruptMessage>()
        if (try? context.fetchCount(messageFetch)) == 0 {
            let masterLibrary =
                StressMessages.createMessages(for: corePack!) +
                OverthinkingMessages.createMessages(for: corePack!) +
                ImposterSyndromeMessages.createMessages(for: imposterPack!) +
                StoicMessages.createMessages(for: stoicPack!) // Link Stoic quotes!
              
            for message in masterLibrary { context.insert(message) }
            try? context.save()
        }
    }
}
