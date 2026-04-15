//
//  OverthinkingMessages.swift
//  Interrupt
//
//  Created by Michael Brockman on 3/28/26.
//

import Foundation

struct OverthinkingMessages {
    static let packID = "core"
    static let category = "Overthinking"
    
    static func createMessages(for pack: ContentPack) -> [InterruptMessage] {
        return [
            InterruptMessage(text: "You cannot think your way out of this. Come back to your body. Name three things you can see right now.", typeRaw: "Affirmation", categoryName: "Overthinking", packID: "core"),
            InterruptMessage(text: "If you are distressed by anything external, the pain is not due to the thing itself, but to your estimate of it.\n— Marcus Aurelius", typeRaw: "Quote", categoryName: "Overthinking", packID: "core"),
            InterruptMessage(text: "Stop measuring the walls of the maze. Look for the exit.", typeRaw: "Affirmation", categoryName: "Overthinking", packID: "core"),
            InterruptMessage(text: "Worrying is carrying tomorrow's load with today's strength - carrying two days at once.", typeRaw: "Affirmation", categoryName: "Overthinking", packID: "core"),
            InterruptMessage(text: "Action is the antidote to despair. \n— Joan Baez - Do one tiny physical thing right now.", typeRaw: "Quote", categoryName: "Overthinking", packID: "core"),
            InterruptMessage(text: "More information will not solve this. Step away and let your subconscious work.", typeRaw: "Affirmation", categoryName: "Overthinking", packID: "core"),
            InterruptMessage(text: "A fool is known by his speech; and a wise man by silence.\n— Pythagoras — Let the mind be silent for a moment.", typeRaw: "Quote", categoryName: "Overthinking", packID: "core"),
            InterruptMessage(text: "Notice that you are spinning. You have permission to put this thought down until tomorrow.", typeRaw: "Affirmation", categoryName: "Overthinking", packID: "core")
        ]
    }
}
