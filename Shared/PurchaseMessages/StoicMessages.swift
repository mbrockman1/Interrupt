//
//  StoicMessages.swift
//  Interrupt
//
//  Created by Michael Brockman on 4/21/26.
//


import Foundation

struct StoicMessages {
    static let packID = "pack.stoic"
    static let category = "Stress" // We'll map these mostly to Stress and Overthinking
    
    static func createMessages(for pack: ContentPack) -> [InterruptMessage] {
        return[
            InterruptMessage(text: "We suffer more often in imagination than in reality.\n— Seneca", typeRaw: "Quote", categoryName: "Overthinking", packID: packID),
            
            InterruptMessage(text: "Man is not worried by real problems so much as by his imagined anxieties about real problems.\n— Epictetus", typeRaw: "Quote", categoryName: "Stress", packID: packID),
            
            InterruptMessage(text: "You have power over your mind - not outside events. Realize this, and you will find strength.\n— Marcus Aurelius", typeRaw: "Quote", categoryName: "Stress", packID: packID),
            
            InterruptMessage(text: "If you are distressed by anything external, the pain is not due to the thing itself, but to your estimate of it; and this you have the power to revoke at any moment.\n— Marcus Aurelius", typeRaw: "Quote", categoryName: "Overthinking", packID: packID),
            
            InterruptMessage(text: "He who fears death will never do anything worth of a man who is alive.\n— Seneca", typeRaw: "Quote", categoryName: "Stress", packID: packID),
            
            InterruptMessage(text: "First say to yourself what you would be; and then do what you have to do.\n— Epictetus", typeRaw: "Quote", categoryName: "Imposter Syndrome", packID: packID),
            
            InterruptMessage(text: "The impediment to action advances action. What stands in the way becomes the way.\n— Marcus Aurelius", typeRaw: "Quote", categoryName: "Stress", packID: packID)
        ]
    }
}
