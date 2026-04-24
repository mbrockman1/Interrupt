//
//  SelfTalkMessages.swift
//  Interrupt
//
//  Created by Michael Brockman on 3/28/26.
//
import Foundation

struct StressMessages {
    static let packID = "core"
    static let category = "Stress"
    
    static func createMessages(for pack: ContentPack) -> [InterruptMessage] {
        return [
            InterruptMessage(text: "You have power over your mind - not outside events. Realize this, and you will find strength.\n— Marcus Aurelius", typeRaw: "Quote", categoryName: category, packID: packID),
            InterruptMessage(text: "Drop your shoulders. Unclench your jaw. Relax your tongue from the roof of your mouth.", typeRaw: "Affirmation", categoryName: category, packID: packID),
            InterruptMessage(text: "Do you have the patience to wait till your mud settles and the water is clear?\n— Lao Tzu", typeRaw: "Quote", categoryName: category, packID: packID),
            InterruptMessage(text: "You only need to handle the exact moment you are in right now. The future doesn't exist yet.", typeRaw: "Affirmation", categoryName: category, packID: packID),
            InterruptMessage(text: "Peace is the result of retraining your mind to process life as it is, rather than as you think it should be.\n— Wayne Dyer", typeRaw: "Quote", categoryName: category, packID: packID),
            InterruptMessage(text: "Inhale for 4 seconds. Exhale for 6. You are safe in this physical moment.", typeRaw: "Affirmation", categoryName: category, packID: packID),
            InterruptMessage(text: "Rule number one is, don’t sweat the small stuff. Rule number two is, it’s all small stuff.\n— Richard Carlson", typeRaw: "Quote", categoryName: category, packID: packID),
            InterruptMessage(text: "This feels overwhelming because you are trying to solve everything at once. Pick one tiny thing.", typeRaw: "Affirmation", categoryName: category, packID: packID)
        ]
    }
}
