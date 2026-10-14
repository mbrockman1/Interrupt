//
//  StoicMessages.swift
//  Interrupt
//
//  Created by Michael Brockman on 4/21/26.
//


import Foundation

struct StoicMessages {
    static let packID = "pack.stoic"
        
    static func createMessages(for pack: ContentPack) -> [InterruptMessage] {
        return[
            InterruptMessage(text: "We suffer more often in imagination than in reality.\n— Seneca", typeRaw: "Quote", categoryName: InterruptMessage.unlinkedCategory, packID: packID, isActive: pack.isPurchased),
            
            InterruptMessage(text: "Man is not worried by real problems so much as by his imagined anxieties about real problems.\n— Epictetus", typeRaw: "Quote", categoryName: InterruptMessage.unlinkedCategory, packID: packID, isActive: pack.isPurchased),
            
            InterruptMessage(text: "You have power over your mind - not outside events. Realize this, and you will find strength.\n— Marcus Aurelius", typeRaw: "Quote", categoryName: InterruptMessage.unlinkedCategory, packID: packID, isActive: pack.isPurchased),
            
            InterruptMessage(text: "If you are distressed by anything external, the pain is not due to the thing itself, but to your estimate of it; and this you have the power to revoke at any moment.\n— Marcus Aurelius", typeRaw: "Quote", categoryName: InterruptMessage.unlinkedCategory, packID: packID, isActive: pack.isPurchased),
            
            InterruptMessage(text: "He who fears death will never do anything worth of a man who is alive.\n— Seneca", typeRaw: "Quote", categoryName: InterruptMessage.unlinkedCategory, packID: packID, isActive: pack.isPurchased),
            
            InterruptMessage(text: "First say to yourself what you would be; and then do what you have to do.\n— Epictetus", typeRaw: "Quote", categoryName: InterruptMessage.unlinkedCategory, packID: packID, isActive: pack.isPurchased),
            
            InterruptMessage(text: "The impediment to action advances action. What stands in the way becomes the way.\n— Marcus Aurelius", typeRaw: "Quote", categoryName: InterruptMessage.unlinkedCategory, packID: packID, isActive: pack.isPurchased)
        ]
    }
}

struct ScienceFactsMessages {
    static let packID = "pack.sciencefacts"

    static func createMessages(for pack: ContentPack) -> [InterruptMessage] {
        let isActive = pack.isPurchased
        func fact(_ text: String) -> InterruptMessage {
            InterruptMessage(text: text, typeRaw: "Affirmation", categoryName: InterruptMessage.unlinkedCategory, packID: packID, isActive: isActive)
        }
        return [
            fact("Your brain uses about 20% of your body's energy while making up only about 2% of its weight. Endless rumination is expensive. Give it a rest."),
            fact("Naming an emotion out loud reduces activity in the brain's alarm center, the amygdala. Say what you feel: \"I notice I'm anxious.\""),
            fact("Your brain keeps forming new connections throughout life. A thought loop is a habit, and habits can be reshaped."),
            fact("A longer exhale than inhale activates the parasympathetic nervous system and slows your heart rate. Breathe out slowly."),
            fact("Adrenaline fades within minutes once your body senses you are safe. The surge is built to be temporary."),
            fact("Sunlight takes about 8 minutes to reach Earth. Intense moments arrive, peak, and pass. This one will too."),
            fact("Even a short walk is shown to lower tension and lift mood. Movement is one of the fastest stress relievers we know."),
            fact("Toddlers learning to walk take thousands of steps and fall many times an hour. Nobody calls it failure. It's how learning works."),
            fact("Research on skill and confidence finds that beginners often overestimate their ability while experts tend to underestimate theirs. Doubt can be a sign you know enough to see what you don't."),
            fact("Every expert you admire once couldn't do what they do now. Skill is built, not born.")
        ]
    }
}

struct ScientistsMessages {
    static let packID = "pack.scientists"

    static func createMessages(for pack: ContentPack) -> [InterruptMessage] {
        let isActive = pack.isPurchased
        func quote(_ text: String) -> InterruptMessage {
            InterruptMessage(text: text, typeRaw: "Quote", categoryName: InterruptMessage.unlinkedCategory, packID: packID, isActive: isActive)
        }
        return [
            quote("Nothing in life is to be feared, it is only to be understood. Now is the time to understand more, so that we may fear less.\n— Marie Curie"),
            quote("However difficult life may seem, there is always something you can do and succeed at.\n— Stephen Hawking"),
            quote("We are a way for the cosmos to know itself.\n— Carl Sagan"),
            quote("The first principle is that you must not fool yourself, and you are the easiest person to fool.\n— Richard Feynman"),
            quote("The important thing is not to stop questioning. Curiosity has its own reason for existing.\n— Albert Einstein"),
            quote("Chance favors only the prepared mind.\n— Louis Pasteur"),
            quote("I have no special talents. I am only passionately curious.\n— Albert Einstein"),
            quote("If I have seen further, it is by standing on the shoulders of giants.\n— Isaac Newton"),
            quote("One never notices what has been done; one can only see what remains to be done.\n— Marie Curie"),
            quote("Life is not easy for any of us. But what of that? We must have perseverance and above all confidence in ourselves.\n— Marie Curie")
        ]
    }
}

struct WomenScientistsMessages {
    static let packID = "pack.womenscientists"

    static func createMessages(for pack: ContentPack) -> [InterruptMessage] {
        let isActive = pack.isPurchased
        func quote(_ text: String) -> InterruptMessage {
            InterruptMessage(text: text, typeRaw: "Quote", categoryName: InterruptMessage.unlinkedCategory, packID: packID, isActive: isActive)
        }
        return [
            quote("Those who contemplate the beauty of the earth find reserves of strength that will endure as long as life lasts.\n— Rachel Carson"),
            quote("Above all, don't fear difficult moments. The best comes from them.\n— Rita Levi-Montalcini"),
            quote("Like what you do, and then you will do your best.\n— Katherine Johnson"),
            quote("Science and everyday life cannot and should not be separated.\n— Rosalind Franklin"),
            quote("We especially need imagination in science.\n— Maria Mitchell"),
            quote("Don't let anyone rob you of your imagination, your creativity, or your curiosity.\n— Mae Jemison"),
            quote("What you do makes a difference, and you have to decide what kind of difference you want to make.\n— Jane Goodall"),
            quote("If you know you are on the right track, if you have this inner knowledge, then nobody can turn you off.\n— Barbara McClintock"),
            quote("That brain of mine is something more than merely mortal; as time will show.\n— Ada Lovelace"),
            quote("The more clearly we can focus our attention on the wonders and realities of the universe about us, the less taste we shall have for destruction.\n— Rachel Carson")
        ]
    }
}


// MARK: - Paid inspiration packs ($0.99 each)
// Like every assignable pack, these ship with no emotions. The user chooses which emotions a pack serves.

struct CatalogPack {
    let id: String
    let title: String
    let subtitle: String
    let typeRaw: String
    let quotes: [String]

    func createMessages(for pack: ContentPack) -> [InterruptMessage] {
        quotes.map {
            InterruptMessage(text: $0, typeRaw: typeRaw, categoryName: InterruptMessage.unlinkedCategory, packID: id, isActive: pack.isPurchased)
        }
    }

    func makePack() -> ContentPack {
        ContentPack(id: id, title: title, subtitle: subtitle, isPurchased: false, isPremium: true)
    }
}

enum InspirationPacks {
    static let all: [CatalogPack] = [
        CatalogPack(
            id: "pack.earnedit", title: "Earned It", subtitle: "Reframes for feeling like a fraud.", typeRaw: "Affirmation",
            quotes: [
                "Feeling like a fraud is not evidence that you are one. It is evidence that you care about doing this well.",
                "Someone saw something real in you when they chose you. Their judgment is data too.",
                "Capable people tend to doubt themselves more than they should. Your doubt is not a verdict.",
                "List what you have actually done, not what you feel. Feelings are not a résumé. Facts are.",
                "You do not need to know everything. You need to know how to find out. That is what every expert does.",
                "Nobody is born knowing how to do their job. Everyone in the room was a beginner once, and most still feel like one.",
                "Being new at something is not the same as not belonging. You belong first. Mastery follows.",
                "Say thank you to the next compliment without explaining it away. You are allowed to accept it.",
                "Luck does not show up and do the work for you. You prepared, you showed up, you delivered.",
                "One mistake does not cancel everything you have achieved. It adds to everything you have learned."
            ]),
        CatalogPack(
            id: "pack.selfcompassion", title: "Be Kind to Yourself", subtitle: "Gentler words for hard moments.", typeRaw: "Affirmation",
            quotes: [
                "Talk to yourself the way you would talk to a close friend having the same bad day.",
                "This is a hard moment. Hard moments are part of being human. May I be kind to myself right now.",
                "You do not have to earn rest. You are allowed to pause just because you are tired.",
                "Being hard on yourself has never made you feel better for long. Try gentleness instead.",
                "You are doing the best you can with what you have right now. That is enough for today.",
                "Put a hand on your chest. Feel it rise and fall. You are here, and that is a good place to start.",
                "A feeling is not a problem to solve. Let it be here, and let it pass in its own time.",
                "You can be a work in progress and still deserve care.",
                "Mistakes are how people learn. They are not proof that you are broken.",
                "Everyone you know carries something heavy. You are allowed to carry yours with some tenderness."
            ]),
        CatalogPack(
            id: "pack.courage", title: "Daily Courage", subtitle: "A nudge to begin before you feel ready.", typeRaw: "Affirmation",
            quotes: [
                "You do not have to feel ready. Courage is taking the next small step while you are still afraid.",
                "Start before you are certain. Clarity usually arrives after the first step, not before it.",
                "Fear and excitement feel almost the same in the body. Try telling yourself you are excited.",
                "A small step today beats a perfect plan someday.",
                "Ask the question. Send the message. Raise your hand. The discomfort lasts minutes. Regret can last years.",
                "You have survived every hard day so far. That is a perfect track record.",
                "Bravery is not the absence of nerves. It is doing what matters while they are there.",
                "The person you hope to become is built from the choices you make today.",
                "Doing it badly beats not doing it. You cannot improve what does not exist yet.",
                "Today does not have to be your best day. It only has to move you one step forward."
            ]),
        CatalogPack(
            id: "pack.bounceback", title: "Bounce Back", subtitle: "Perspective after a setback or rejection.", typeRaw: "Affirmation",
            quotes: [
                "A setback is a detour, not a dead end. Look for the next road.",
                "Rejection is information about fit. It is not a verdict on your worth.",
                "You are allowed to feel disappointed. Feel it fully, then ask what you can take from it.",
                "Everyone you admire has a pile of failures you never saw.",
                "One bad day, one bad meeting, one bad result: none of them is your whole story.",
                "You have recovered from hard things before. The strength you used is still yours.",
                "Failing means you tried something. That is more than most people do.",
                "Do not judge a project by its messy middle. Everything looks like a mistake halfway through.",
                "What happened is done. What you do next is still up to you.",
                "Rest, then try again. Quitting after one attempt would have ended every success story before it began."
            ]),
        CatalogPack(
            id: "pack.grounding", title: "Grounding Cues", subtitle: "Body-first prompts to settle in seconds.", typeRaw: "Affirmation",
            quotes: [
                "Name five things you can see right now. Let your eyes rest on each one.",
                "Feel your feet on the floor. Press down gently. You are supported.",
                "Unclench your jaw. Let your tongue rest. Drop your shoulders away from your ears.",
                "Breathe in for four, out for six. Do it three times and notice what shifts.",
                "Hold something cold or textured. Let your hands tell your mind that you are here, in this room.",
                "Name four things you can touch, three you can hear, two you can smell, and one you can taste.",
                "Look slowly around the room and find something blue. Then something round. Let your mind follow your eyes.",
                "Roll your shoulders back. Stretch your neck side to side. Your body has been holding a lot.",
                "Take a slow sip of water. Notice the temperature and the swallow.",
                "Say it quietly: I am here, and I can get through this moment. Then take one more slow breath."
            ]),
        CatalogPack(
            id: "pack.progress", title: "Progress Over Perfection", subtitle: "Release the pressure to get it flawless.", typeRaw: "Affirmation",
            quotes: [
                "Done is better than perfect. Perfect never ships.",
                "Good enough is a real standard. Aim for it, then move on.",
                "A rough first draft is a gift to your future self. Editing is easier than starting.",
                "Small progress is still progress. Count it.",
                "You are allowed to be a beginner. Everyone's first attempt is rough.",
                "Perfection is a moving target. You will never catch it, so choose a finish line instead.",
                "Ask whether this will matter in a week, a month, a year. Spend your effort accordingly.",
                "Ninety percent done and shared beats a hundred percent perfect and hidden.",
                "Mistakes in the middle are part of the process, not a sign that it is failing.",
                "Celebrate the step you just took. Then take the next one."
            ]),
        CatalogPack(
            id: "pack.comparison", title: "Stop Comparing", subtitle: "Step out of the comparison trap.", typeRaw: "Affirmation",
            quotes: [
                "You are comparing your behind-the-scenes to everyone else's highlight reel.",
                "Someone else's success does not use up your share. There is room for you too.",
                "Their path is not your path. You cannot see their doubts, their luck, or what it cost them.",
                "Close the app. Your life is happening right here, not in a feed.",
                "Envy can be a compass. Ask what it points to that you want, then take one step toward it.",
                "Measure yourself against who you were yesterday, not against anyone else's best moment.",
                "Everyone you envy is comparing themselves to someone too.",
                "Be happy for them and kind to yourself. Both can be true.",
                "You are not behind. There is no universal schedule.",
                "Different timelines are not wrong timelines. You are allowed to move at your own pace."
            ]),
        CatalogPack(
            id: "pack.voices", title: "Voices of Courage", subtitle: "Timeless words from writers and poets.", typeRaw: "Quote",
            quotes: [
                "If one advances confidently in the direction of his dreams, and endeavors to live the life which he has imagined, he will meet with a success unexpected in common hours.\n— Henry David Thoreau",
                "Nothing great was ever achieved without enthusiasm.\n— Ralph Waldo Emerson",
                "Trust thyself: every heart vibrates to that iron string.\n— Ralph Waldo Emerson",
                "Do I contradict myself? Very well then I contradict myself, (I am large, I contain multitudes.)\n— Walt Whitman",
                "To strive, to seek, to find, and not to yield.\n— Alfred, Lord Tennyson",
                "Hope is the thing with feathers that perches in the soul.\n— Emily Dickinson",
                "If there is no struggle, there is no progress.\n— Frederick Douglass",
                "I am no bird; and no net ensnares me: I am a free human being with an independent will.\n— Charlotte Brontë",
                "I am not afraid of storms, for I am learning how to sail my ship.\n— Louisa May Alcott",
                "A journey of a thousand miles begins with a single step.\n— Lao Tzu"
            ])
    ]
}
