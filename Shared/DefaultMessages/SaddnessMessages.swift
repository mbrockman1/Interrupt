//
//  Depression.swift
//  Interrupt
//
//  Created by Michael Brockman on 3/28/26.
//

import Foundation

struct SaddnessMessages {
    static let packID = "core"
    static let category = "Saddness"
    
    static func createMessages(for pack: ContentPack) -> [InterruptMessage] {
        return [
            InterruptMessage(text: "The wound is the place where the Light enters you.\n— Rumi", typeRaw: "Quote", categoryName: "Saddness", packID: "core"),
            InterruptMessage(text: "This feeling is heavy, but it is not permanent. Like the weather, it will shift.", typeRaw: "Affirmation", categoryName: "Saddness", packID: "core"),
            InterruptMessage(text: "Courage doesn't always roar. Sometimes courage is the quiet voice at the end of the day saying, 'I will try again tomorrow.'\n— Mary Anne Radmacher", typeRaw: "Quote", categoryName: "Saddness", packID: "core"),
            InterruptMessage(text: "You don't have to have it all figured out today. Just get through this hour.", typeRaw: "Affirmation", categoryName: "Saddness", packID: "core"),
            InterruptMessage(text: "There is a crack in everything, that's how the light gets in.\n— Leonard Cohen", typeRaw: "Quote", categoryName: "Saddness", packID: "core"),
            InterruptMessage(text: "Your track record for surviving bad days is exactly 100%. Keep going.", typeRaw: "Affirmation", categoryName: "Saddness", packID: "core"),
            InterruptMessage(text: "Be gentle with yourself. You are doing the best you can with the energy you have right now.", typeRaw: "Affirmation", categoryName: "Saddness", packID: "core"),
            InterruptMessage(text: "Fall seven times, stand up eight.\n— Japanese Proverb", typeRaw: "Quote", categoryName: "Saddness", packID: "core"),
        ]
    }
}
