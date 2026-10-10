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

struct ScienceFactsMessages {
    static let packID = "pack.sciencefacts"

    static func createMessages(for pack: ContentPack) -> [InterruptMessage] {
        let isActive = pack.isPurchased
        func fact(_ text: String, _ category: String) -> InterruptMessage {
            InterruptMessage(text: text, typeRaw: "Affirmation", categoryName: category, packID: packID, isActive: isActive)
        }
        return [
            fact("Your brain uses about 20% of your body's energy while making up only about 2% of its weight. Endless rumination is expensive. Give it a rest.", "Overthinking"),
            fact("Naming an emotion out loud reduces activity in the brain's alarm center, the amygdala. Say what you feel: \"I notice I'm anxious.\"", "Overthinking"),
            fact("Your brain keeps forming new connections throughout life. A thought loop is a habit, and habits can be reshaped.", "Overthinking"),
            fact("A longer exhale than inhale activates the parasympathetic nervous system and slows your heart rate. Breathe out slowly.", "Stress"),
            fact("Adrenaline fades within minutes once your body senses you are safe. The surge is built to be temporary.", "Stress"),
            fact("Sunlight takes about 8 minutes to reach Earth. Intense moments arrive, peak, and pass. This one will too.", "Stress"),
            fact("Even a short walk is shown to lower tension and lift mood. Movement is one of the fastest stress relievers we know.", "Stress"),
            fact("Toddlers learning to walk take thousands of steps and fall many times an hour. Nobody calls it failure. It's how learning works.", "Imposter Syndrome"),
            fact("Research on skill and confidence finds that beginners often overestimate their ability while experts tend to underestimate theirs. Doubt can be a sign you know enough to see what you don't.", "Imposter Syndrome"),
            fact("Every expert you admire once couldn't do what they do now. Skill is built, not born.", "Imposter Syndrome")
        ]
    }
}

struct ScientistsMessages {
    static let packID = "pack.scientists"

    static func createMessages(for pack: ContentPack) -> [InterruptMessage] {
        let isActive = pack.isPurchased
        func quote(_ text: String, _ category: String) -> InterruptMessage {
            InterruptMessage(text: text, typeRaw: "Quote", categoryName: category, packID: packID, isActive: isActive)
        }
        return [
            quote("Nothing in life is to be feared, it is only to be understood. Now is the time to understand more, so that we may fear less.\n— Marie Curie", "Stress"),
            quote("However difficult life may seem, there is always something you can do and succeed at.\n— Stephen Hawking", "Stress"),
            quote("We are a way for the cosmos to know itself.\n— Carl Sagan", "Stress"),
            quote("The first principle is that you must not fool yourself, and you are the easiest person to fool.\n— Richard Feynman", "Overthinking"),
            quote("The important thing is not to stop questioning. Curiosity has its own reason for existing.\n— Albert Einstein", "Overthinking"),
            quote("Chance favors only the prepared mind.\n— Louis Pasteur", "Overthinking"),
            quote("I have no special talents. I am only passionately curious.\n— Albert Einstein", "Imposter Syndrome"),
            quote("If I have seen further, it is by standing on the shoulders of giants.\n— Isaac Newton", "Imposter Syndrome"),
            quote("One never notices what has been done; one can only see what remains to be done.\n— Marie Curie", "Imposter Syndrome"),
            quote("Life is not easy for any of us. But what of that? We must have perseverance and above all confidence in ourselves.\n— Marie Curie", "Imposter Syndrome")
        ]
    }
}

struct WomenScientistsMessages {
    static let packID = "pack.womenscientists"

    static func createMessages(for pack: ContentPack) -> [InterruptMessage] {
        let isActive = pack.isPurchased
        func quote(_ text: String, _ category: String) -> InterruptMessage {
            InterruptMessage(text: text, typeRaw: "Quote", categoryName: category, packID: packID, isActive: isActive)
        }
        return [
            quote("Those who contemplate the beauty of the earth find reserves of strength that will endure as long as life lasts.\n— Rachel Carson", "Stress"),
            quote("Above all, don't fear difficult moments. The best comes from them.\n— Rita Levi-Montalcini", "Stress"),
            quote("Like what you do, and then you will do your best.\n— Katherine Johnson", "Stress"),
            quote("Science and everyday life cannot and should not be separated.\n— Rosalind Franklin", "Overthinking"),
            quote("We especially need imagination in science.\n— Maria Mitchell", "Overthinking"),
            quote("Don't let anyone rob you of your imagination, your creativity, or your curiosity.\n— Mae Jemison", "Overthinking"),
            quote("What you do makes a difference, and you have to decide what kind of difference you want to make.\n— Jane Goodall", "Imposter Syndrome"),
            quote("If you know you are on the right track, if you have this inner knowledge, then nobody can turn you off.\n— Barbara McClintock", "Imposter Syndrome"),
            quote("That brain of mine is something more than merely mortal; as time will show.\n— Ada Lovelace", "Imposter Syndrome"),
            quote("The more clearly we can focus our attention on the wonders and realities of the universe about us, the less taste we shall have for destruction.\n— Rachel Carson", "Overthinking")
        ]
    }
}
