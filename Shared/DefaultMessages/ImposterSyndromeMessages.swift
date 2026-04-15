//
//  ImposterSyndromeMessages.swift
//  Interrupt
//
//  Created by Michael Brockman on 4/13/26.
//


import Foundation

struct ImposterSyndromeMessages {
    static let packID = "pack.imposter" // Keeping it in the free Essentials pack
    static let category = "Imposter Syndrome"
    
    static func createMessages(for pack: ContentPack) -> [InterruptMessage] {
        return [
            InterruptMessage(text: "The exaggerated esteem in which my lifework is held makes me very ill at ease. I feel compelled to think of myself as an involuntary swindler.\n— Albert Einstein", typeRaw: "Quote", categoryName: category, packID: packID),
            
            InterruptMessage(text: "If you feel like an imposter, it means you are pushing your boundaries. Actual frauds do not experience imposter syndrome.\n— Interrupt", typeRaw: "Affirmation", categoryName: category, packID: packID),
            
            InterruptMessage(text: "I have written eleven books, but each time I think, 'Uh oh, they’re going to find out now. I’ve run a game on everybody.'\n— Maya Angelou", typeRaw: "Quote", categoryName: category, packID: packID),
            
            InterruptMessage(text: "You are not an imposter. You are a beginner, a learner, or simply human. Give yourself permission to not know everything yet.\n— Interrupt", typeRaw: "Affirmation", categoryName: category, packID: packID),
            
            InterruptMessage(text: "We all have doubts in our abilities, about our power and what that power is. It doesn’t go away.\n— Michelle Obama", typeRaw: "Quote", categoryName: category, packID: packID),
            
            InterruptMessage(text: "Every expert was once a beginner. Confidence is built through doing, not by knowing everything in advance.\n— Interrupt", typeRaw: "Affirmation", categoryName: category, packID: packID),
            
            InterruptMessage(text: "You don't have to be perfect to be worthy of being here. Your unique perspective is exactly what is needed right now.\n— Interrupt", typeRaw: "Affirmation", categoryName: category, packID: packID),
            
            InterruptMessage(text: "The only difference between you and the people you admire is that they learned to act alongside their self-doubt, not without it.\n— Interrupt", typeRaw: "Affirmation", categoryName: category, packID: packID)
        ]
    }
}
