import XCTest
@testable import Interrupt

@MainActor
final class PackContentTests: XCTestCase {
    private let validCategories: Set<String> = ["Stress", "Overthinking", "Imposter Syndrome"]

    private func makePacks() -> [(String, [InterruptMessage])] {
        let science = ContentPack(id: ScienceFactsMessages.packID, title: "", subtitle: "")
        let scientists = ContentPack(id: ScientistsMessages.packID, title: "", subtitle: "")
        let women = ContentPack(id: WomenScientistsMessages.packID, title: "", subtitle: "", isPremium: true)
        let stoic = ContentPack(id: StoicMessages.packID, title: "", subtitle: "", isPremium: true)
        return [
            (science.id, ScienceFactsMessages.createMessages(for: science)),
            (scientists.id, ScientistsMessages.createMessages(for: scientists)),
            (women.id, WomenScientistsMessages.createMessages(for: women)),
            (stoic.id, StoicMessages.createMessages(for: stoic))
        ]
    }

    func testMessagesCarryTheirPackID() {
        for (id, messages) in makePacks() {
            XCTAssertTrue(messages.allSatisfy { $0.packID == id }, id)
        }
    }

    func testEveryMessageMapsToADefaultEmotion() {
        for (id, messages) in makePacks() {
            for m in messages {
                XCTAssertTrue(validCategories.contains(m.categoryName), "\(id): '\(m.categoryName)' has no matching trigger")
            }
        }
    }

    func testEveryDefaultEmotionIsCoveredByEachNewPack() {
        for (id, messages) in makePacks() where id != StoicMessages.packID {
            XCTAssertEqual(Set(messages.map(\.categoryName)), validCategories, id)
        }
    }

    func testMessagesAreNonEmptyAndUnique() {
        var seen = Set<String>()
        for (id, messages) in makePacks() {
            for m in messages {
                XCTAssertFalse(m.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, id)
                XCTAssertTrue(seen.insert(m.text).inserted, "Duplicate quote: \(m.text)")
            }
        }
    }

    func testScientistQuotesAreAttributed() {
        let pack = ContentPack(id: ScientistsMessages.packID, title: "", subtitle: "")
        for m in ScientistsMessages.createMessages(for: pack) + WomenScientistsMessages.createMessages(for: pack) {
            XCTAssertTrue(m.text.contains("\n— "), "Missing attribution: \(m.text)")
            XCTAssertEqual(m.typeRaw, "Quote")
        }
    }

    func testFactsAreAffirmations() {
        let pack = ContentPack(id: ScienceFactsMessages.packID, title: "", subtitle: "")
        XCTAssertTrue(ScienceFactsMessages.createMessages(for: pack).allSatisfy { $0.typeRaw == "Affirmation" })
    }

    func testMessagesStartActiveOnlyWhenPackIsOwned() {
        let locked = ContentPack(id: ScienceFactsMessages.packID, title: "", subtitle: "", isPurchased: false)
        let owned = ContentPack(id: ScienceFactsMessages.packID, title: "", subtitle: "", isPurchased: true)
        XCTAssertTrue(ScienceFactsMessages.createMessages(for: locked).allSatisfy { !$0.isActive })
        XCTAssertTrue(ScienceFactsMessages.createMessages(for: owned).allSatisfy(\.isActive))
    }

    func testDictionaryRoundTripPreservesPackAndActiveState() throws {
        let m = InterruptMessage(text: "t", typeRaw: "Quote", categoryName: "Stress", packID: "pack.scientists", isActive: false)
        let copy = try XCTUnwrap(InterruptMessage.fromDictionary(m.toDictionary()))
        XCTAssertEqual(copy.id, m.id)
        XCTAssertEqual(copy.packID, "pack.scientists")
        XCTAssertFalse(copy.isActive)
    }

    func testStoreProductIDsAreRegistered() {
        XCTAssertTrue(StoreManager.shared.productIDs.contains("pack.stoic"))
        XCTAssertTrue(StoreManager.shared.productIDs.contains(WomenScientistsMessages.packID))
        XCTAssertFalse(StoreManager.shared.productIDs.contains(ScienceFactsMessages.packID))
        XCTAssertFalse(StoreManager.shared.productIDs.contains(ScientistsMessages.packID))
    }
}
