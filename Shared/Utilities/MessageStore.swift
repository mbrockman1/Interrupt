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
        let filtered = allMessages.filter { $0.categoryName == categoryName && $0.isActive }
        
        if let msg = filtered.randomElement() { return msg }
        
        // Deterministic memory fallback
        let fallbacks = fallbackPool[categoryName] ?? [InterruptMessage(text: "Breathe. Let it go.", typeRaw: "Affirmation", categoryName: categoryName)]
        return fallbacks.randomElement()!
    }
}
