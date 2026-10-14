import Foundation
import SwiftData

@MainActor
final class MessageStore {
    static let shared = MessageStore()
    
    // FIXED HERE: Dictionary uses String keys now
    private let fallbackPool: [String: [InterruptMessage]] = [
        "Stress": [
            InterruptMessage(text: "Drop your shoulders. Unclench your jaw.", typeRaw: "Affirmation", categoryName: "Stress"),
            InterruptMessage(text: "You only need to handle the exact moment you are in right now.", typeRaw: "Affirmation", categoryName: "Stress")
        ],
        "Overthinking": [
            InterruptMessage(text: "You cannot think your way out of this. Come back to your body. Name three things you can see.", typeRaw: "Affirmation", categoryName: "Overthinking")
        ],
        "Imposter Syndrome":[
                    InterruptMessage(
                        text: "If you feel like an imposter, it means you are pushing your boundaries. Actual frauds do not experience imposter syndrome.\n— Interrupt",
                        typeRaw: "Affirmation",
                        categoryName: "Imposter Syndrome"
                    )
                ]
    ]
    
    // FIXED HERE: categoryName is passed as a String
    func getMessage(for categoryName: String, context: ModelContext) -> InterruptMessage {
        let fetchDescriptor = FetchDescriptor<InterruptMessage>()
        let allMessages = (try? context.fetch(fetchDescriptor)) ?? []
        let filtered = allMessages.filter { $0.isActive && $0.matches(emotion: categoryName) }

        if let msg = filtered.randomElement() {
            if msg.categoryName == categoryName { return msg }
            // Served through a pack assignment: hand back an unsaved copy tagged with the emotion
            // that was tapped, so breathing settings and sharing key off the right emotion.
            return InterruptMessage(id: msg.id, text: msg.text, typeRaw: msg.typeRaw, categoryName: categoryName, packID: msg.packID)
        }
        
        // Deterministic memory fallback
        let fallbacks = fallbackPool[categoryName] ?? [InterruptMessage(text: "Breathe. Let it go.", typeRaw: "Affirmation", categoryName: categoryName)]
        return fallbacks.randomElement()!
    }
}


// Reads and writes which emotions a pack serves. Every message in a pack carries the same list,
// so the watch (which only receives messages) needs no pack-level state.
@MainActor
enum PackAssignment {
    static func assignedEmotions(packID: String, in messages: [InterruptMessage]) -> Set<String> {
        var result = Set<String>()
        for message in messages where message.packID == packID { result.formUnion(message.assignedEmotions) }
        return result
    }

    static func setAssignedEmotions(_ emotions: Set<String>, packID: String, context: ModelContext) {
        let fetch = FetchDescriptor<InterruptMessage>(predicate: #Predicate { $0.packID == packID })
        let list = emotions.sorted()
        for message in (try? context.fetch(fetch)) ?? [] {
            message.assignedEmotions = list
            message.categoryName = InterruptMessage.unlinkedCategory
        }
        do { try context.save() } catch { print("❌ Failed to save pack assignment: \(error)") }
        if let all = try? context.fetch(FetchDescriptor<InterruptMessage>()) {
            WatchSyncManager.shared.syncLibraryToWatch(messages: all)
        }
    }

    // Used when an emotion is deleted so no pack keeps pointing at it.
    static func removeEmotion(_ name: String, from messages: [InterruptMessage]) {
        for message in messages where message.assignedEmotions.contains(name) {
            message.assignedEmotions = message.assignedEmotions.filter { $0 != name }
        }
    }
}
