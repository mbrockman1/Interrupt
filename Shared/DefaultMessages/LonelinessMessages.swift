//
//  Loneliness.swift
//  Interrupt
//
//  Created by Michael Brockman on 3/28/26.
//

import Foundation

struct LonelinessMessages {
    static let packID = "core"
    static let category = "Loneliness"
    static func createMessages(for pack: ContentPack) -> [InterruptMessage] {
        return [
            InterruptMessage(text: "You are not a drop in the ocean. You are the entire ocean in a drop.\n— Rumi", typeRaw: "Quote", categoryName: "Loneliness", packID: "core"),
            InterruptMessage(text: "You are deeply connected to the human experience. Millions of others are feeling exactly this way right now.", typeRaw: "Affirmation", categoryName: "Loneliness", packID: "core"),
            InterruptMessage(text: "We are like islands in the sea, separate on the surface but connected in the deep.\n— William James", typeRaw: "Quote", categoryName: "Loneliness", packID: "core"),
            InterruptMessage(text: "Loneliness is proof that your innate, healthy search for connection is fully intact.", typeRaw: "Affirmation", categoryName: "Loneliness", packID: "core"),
            InterruptMessage(text: "The cosmos is within us. We are made of star-stuff. We are a way for the universe to know itself.\n— Carl Sagan", typeRaw: "Quote", categoryName: "Loneliness", packID: "core"),
            InterruptMessage(text: "You are worthy of love and belonging, exactly as you are right now.", typeRaw: "Affirmation", categoryName: "Loneliness", packID: "core"),
            InterruptMessage(text: "I am a part of all that I have met.\n— Alfred Lord Tennyson", typeRaw: "Quote", categoryName: "", packID: "core"),
            InterruptMessage(text: "Solitude is the place of purification. Take a deep breath and just be with yourself.", typeRaw: "Affirmation", categoryName: "Loneliness", packID: "core"),
        ]
    }
}
