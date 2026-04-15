//
//  SelfTalkMessages.swift
//  Interrupt
//
//  Created by Michael Brockman on 3/28/26.
//


import Foundation

struct SelfTalkMessages {
    static let packID = "core"
    static let category = "Negative Self-Talk"
    
    static func createMessages(for pack: ContentPack) -> [InterruptMessage] {
        return [
            InterruptMessage(text: "We suffer more often in imagination than in reality.\n— Seneca", typeRaw: "Quote", categoryName: "Negative Self-Talk", packID: "core"),
            InterruptMessage(text: "Would you say this to a friend? Speak to yourself with the exact same compassion.", typeRaw: "Affirmation", categoryName: "Negative Self-Talk", packID: "core"),
            InterruptMessage(text: "You are not your thoughts. You are the observer of your thoughts.", typeRaw: "Affirmation", categoryName: "Negative Self-Talk", packID: "core"),
            InterruptMessage(text: "No one can make you feel inferior without your consent.\n— Eleanor Roosevelt", typeRaw: "Quote", categoryName: "Negative Self-Talk", packID: "core"),
            InterruptMessage(text: "Your mind is a suggestion engine. This thought is just a suggestion, not a fact.", typeRaw: "Affirmation", categoryName: "Negative Self-Talk", packID: "core"),
            InterruptMessage(text: "Talk to yourself like you would to someone you love.\n— Brené Brown", typeRaw: "Quote", categoryName: "Negative Self-Talk", packID: "core"),
            InterruptMessage(text: "Is this thought helpful, or is it just familiar?", typeRaw: "Affirmation", categoryName: "Negative Self-Talk", packID: "core"),
            InterruptMessage(text: "Acknowledge the inner critic, but don't invite it to stay for tea.", typeRaw: "Affirmation", categoryName: "Negative Self-Talk", packID: "core")
        ]
    }
}
