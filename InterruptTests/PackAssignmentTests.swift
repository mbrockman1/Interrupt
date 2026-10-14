import XCTest
import SwiftData
@testable import Interrupt

@MainActor
final class PackAssignmentTests: XCTestCase {
    var context: ModelContext!
    private let defaultEmotions = ["Stress", "Overthinking", "Imposter Syndrome"]

    override func setUp() async throws {
        context = try TestSupport.makeContext()
        SeedManager.seedDatabaseIfNeeded(context: context)
    }

    private func unlock(_ id: String) throws -> ContentPack {
        let pack = try TestSupport.packs(in: context)[id]!
        StoreManager.shared.unlockPack(pack, context: context)
        return pack
    }

    // MARK: Catalog

    func testCatalogHasEightPaidPacksWithTenQuotesEach() {
        XCTAssertEqual(InspirationPacks.all.count, 8)
        XCTAssertEqual(Set(InspirationPacks.all.map(\.id)).count, 8, "Product IDs must be unique")
        for catalog in InspirationPacks.all {
            XCTAssertEqual(catalog.quotes.count, 10, catalog.id)
            XCTAssertTrue(catalog.id.hasPrefix("pack."), catalog.id)
            XCTAssertFalse(catalog.title.isEmpty)
            XCTAssertFalse(catalog.subtitle.isEmpty)
            XCTAssertTrue(catalog.makePack().isPremium, "\(catalog.id) must be a paid pack")
            XCTAssertFalse(catalog.makePack().isPurchased)
        }
    }

    func testCatalogQuotesAreUniqueAcrossAllPacks() {
        var seen = Set<String>()
        for catalog in InspirationPacks.all {
            for quote in catalog.quotes {
                XCTAssertFalse(quote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                XCTAssertTrue(seen.insert(quote).inserted, "Duplicate quote: \(quote)")
            }
        }
    }

    func testAttributedCatalogPackCitesEveryAuthor() throws {
        let voices = try XCTUnwrap(InspirationPacks.all.first { $0.id == "pack.voices" })
        XCTAssertEqual(voices.typeRaw, "Quote")
        XCTAssertTrue(voices.quotes.allSatisfy { $0.contains("\n— ") })
    }

    func testCatalogPacksAreSeededLockedAndInactive() throws {
        for catalog in InspirationPacks.all {
            let messages = try TestSupport.messages(packID: catalog.id, in: context)
            XCTAssertEqual(messages.count, 10, catalog.id)
            XCTAssertTrue(messages.allSatisfy { !$0.isActive }, catalog.id)
        }
    }

    // MARK: No pre-assigned emotions

    func testEveryAssignablePackShipsWithoutEmotions() throws {
        let packs = try context.fetch(FetchDescriptor<ContentPack>()).filter(\.usesEmotionAssignment)
        XCTAssertGreaterThanOrEqual(packs.count, 12)
        for pack in packs {
            for m in try TestSupport.messages(packID: pack.id, in: context) {
                XCTAssertEqual(m.categoryName, InterruptMessage.unlinkedCategory, pack.id)
                XCTAssertTrue(m.assignedEmotions.isEmpty, pack.id)
            }
        }
    }

    func testFixedPacksKeepTheirEmotions() throws {
        XCTAssertFalse(ContentPack(id: "core", title: "", subtitle: "").usesEmotionAssignment)
        XCTAssertFalse(ContentPack(id: "pack.imposter", title: "", subtitle: "").usesEmotionAssignment)
        XCTAssertFalse(ContentPack(id: "custom", title: "", subtitle: "").usesEmotionAssignment)
        XCTAssertFalse(ContentPack(id: "received", title: "", subtitle: "").usesEmotionAssignment)
        XCTAssertTrue(ContentPack(id: "pack.stoic", title: "", subtitle: "").usesEmotionAssignment)

        for id in ["core", "pack.imposter"] {
            let categories = Set(try TestSupport.messages(packID: id, in: context).map(\.categoryName))
            XCTAssertTrue(categories.isSubset(of: Set(defaultEmotions)), id)
            XCTAssertFalse(categories.contains(InterruptMessage.unlinkedCategory), id)
        }
    }

    // MARK: Serving

    func testOwnedButUnassignedPackIsNeverServed() throws {
        let pack = try unlock("pack.courage")
        let ids = Set(try TestSupport.messages(packID: pack.id, in: context).map(\.id))
        for emotion in defaultEmotions {
            for _ in 0..<300 {
                XCTAssertFalse(ids.contains(MessageStore.shared.getMessage(for: emotion, context: context).id))
            }
        }
    }

    func testAssignedPackIsServedOnlyForChosenEmotions() throws {
        let pack = try unlock("pack.earnedit")
        PackAssignment.setAssignedEmotions(["Imposter Syndrome"], packID: pack.id, context: context)
        let ids = Set(try TestSupport.messages(packID: pack.id, in: context).map(\.id))

        var servedForChosen = false
        for _ in 0..<3000 where !servedForChosen {
            servedForChosen = ids.contains(MessageStore.shared.getMessage(for: "Imposter Syndrome", context: context).id)
        }
        XCTAssertTrue(servedForChosen)

        for emotion in ["Stress", "Overthinking"] {
            for _ in 0..<300 {
                XCTAssertFalse(ids.contains(MessageStore.shared.getMessage(for: emotion, context: context).id), emotion)
            }
        }
    }

    func testPackCanServeSeveralEmotionsIncludingCustomOnes() throws {
        context.insert(EmotionTrigger(name: "Burnout"))
        let pack = try unlock("pack.bounceback")
        PackAssignment.setAssignedEmotions(["Burnout", "Stress"], packID: pack.id, context: context)
        let ids = Set(try TestSupport.messages(packID: pack.id, in: context).map(\.id))

        for emotion in ["Burnout", "Stress"] {
            var served = false
            for _ in 0..<3000 where !served {
                served = ids.contains(MessageStore.shared.getMessage(for: emotion, context: context).id)
            }
            XCTAssertTrue(served, emotion)
        }
    }

    func testServedAssignedQuoteIsTaggedWithTheTappedEmotion() throws {
        let pack = try unlock("pack.grounding")
        PackAssignment.setAssignedEmotions(["Overthinking"], packID: pack.id, context: context)
        for m in try context.fetch(FetchDescriptor<InterruptMessage>()) where m.packID != pack.id { m.isActive = false }
        let before = try context.fetchCount(FetchDescriptor<InterruptMessage>())

        let served = MessageStore.shared.getMessage(for: "Overthinking", context: context)

        XCTAssertEqual(served.packID, pack.id)
        XCTAssertEqual(served.categoryName, "Overthinking", "Breathing settings key off the tapped emotion")
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<InterruptMessage>()), before, "Served copy must not be saved")
    }

    func testDeactivatedQuoteInAssignedPackIsSkipped() throws {
        let pack = try unlock("pack.progress")
        PackAssignment.setAssignedEmotions(["Stress"], packID: pack.id, context: context)
        let messages = try TestSupport.messages(packID: pack.id, in: context)
        let kept = messages[0]
        for m in messages.dropFirst() { m.isActive = false }
        for m in try context.fetch(FetchDescriptor<InterruptMessage>()) where m.packID != pack.id { m.isActive = false }

        for _ in 0..<50 {
            XCTAssertEqual(MessageStore.shared.getMessage(for: "Stress", context: context).id, kept.id)
        }
    }

    // MARK: Assignment API

    func testSetAssignedEmotionsAppliesToEveryMessageInThePackOnly() throws {
        _ = try unlock("pack.comparison")
        PackAssignment.setAssignedEmotions(["Stress", "Overthinking"], packID: "pack.comparison", context: context)

        for m in try TestSupport.messages(packID: "pack.comparison", in: context) {
            XCTAssertEqual(Set(m.assignedEmotions), ["Stress", "Overthinking"])
        }
        for m in try TestSupport.messages(packID: "pack.voices", in: context) {
            XCTAssertTrue(m.assignedEmotions.isEmpty)
        }
        let all = try context.fetch(FetchDescriptor<InterruptMessage>())
        XCTAssertEqual(PackAssignment.assignedEmotions(packID: "pack.comparison", in: all), ["Stress", "Overthinking"])
    }

    func testAssignmentCanBeClearedAgain() throws {
        _ = try unlock("pack.voices")
        PackAssignment.setAssignedEmotions(["Stress"], packID: "pack.voices", context: context)
        PackAssignment.setAssignedEmotions([], packID: "pack.voices", context: context)
        let all = try context.fetch(FetchDescriptor<InterruptMessage>())
        XCTAssertTrue(PackAssignment.assignedEmotions(packID: "pack.voices", in: all).isEmpty)
    }

    func testAssignmentSurvivesReseed() throws {
        _ = try unlock("pack.selfcompassion")
        PackAssignment.setAssignedEmotions(["Stress"], packID: "pack.selfcompassion", context: context)
        SeedManager.seedDatabaseIfNeeded(context: context)
        let all = try context.fetch(FetchDescriptor<InterruptMessage>())
        XCTAssertEqual(PackAssignment.assignedEmotions(packID: "pack.selfcompassion", in: all), ["Stress"])
    }

    func testRemovingAnEmotionStripsItFromPacks() throws {
        _ = try unlock("pack.courage")
        PackAssignment.setAssignedEmotions(["Stress", "Overthinking"], packID: "pack.courage", context: context)
        let all = try context.fetch(FetchDescriptor<InterruptMessage>())
        PackAssignment.removeEmotion("Stress", from: all)
        XCTAssertEqual(PackAssignment.assignedEmotions(packID: "pack.courage", in: all), ["Overthinking"])
    }

    func testEmotionNamesWithPunctuationRoundTrip() {
        let m = InterruptMessage(text: "t", typeRaw: "Affirmation", categoryName: "Unlinked", packID: "pack.courage",
                                 assignedEmotions: ["Mom, Dad & Me", "Work | Home"])
        XCTAssertEqual(m.assignedEmotions, ["Mom, Dad & Me", "Work | Home"])
        XCTAssertTrue(m.matches(emotion: "Work | Home"))
        XCTAssertFalse(m.matches(emotion: "Mom"))
    }

    // MARK: Watch sync

    func testAssignmentsRoundTripThroughWatchDictionary() throws {
        let m = InterruptMessage(text: "t", typeRaw: "Quote", categoryName: "Unlinked", packID: "pack.voices",
                                 assignedEmotions: ["Stress", "Overthinking"])
        let copy = try XCTUnwrap(InterruptMessage.fromDictionary(m.toDictionary()))
        XCTAssertEqual(copy.assignedEmotions, ["Stress", "Overthinking"])
    }

    func testPayloadFromOlderPhoneWithoutAssignmentsStillDecodes() throws {
        var dict = InterruptMessage(text: "t", typeRaw: "Quote", categoryName: "Stress", packID: "core").toDictionary()
        dict.removeValue(forKey: "assignedEmotions")
        let copy = try XCTUnwrap(InterruptMessage.fromDictionary(dict))
        XCTAssertTrue(copy.assignedEmotions.isEmpty)
        XCTAssertTrue(copy.matches(emotion: "Stress"))
    }

    // MARK: Migration from per-message emotions

    private func legacyContext() throws -> ModelContext {
        let legacy = try TestSupport.makeContext()
        legacy.insert(EmotionTrigger(name: "Stress", isDefault: true))
        let owned = ContentPack(id: "pack.stoic", title: "Stoic", subtitle: "", isPurchased: true, isPremium: true)
        let locked = ContentPack(id: "pack.womenscientists", title: "Women", subtitle: "", isPurchased: false, isPremium: true)
        legacy.insert(owned)
        legacy.insert(locked)
        legacy.insert(InterruptMessage(text: "a", typeRaw: "Quote", categoryName: "Stress", packID: "pack.stoic"))
        legacy.insert(InterruptMessage(text: "b", typeRaw: "Quote", categoryName: "Overthinking", packID: "pack.stoic"))
        legacy.insert(InterruptMessage(text: "c", typeRaw: "Quote", categoryName: "Stress", packID: "pack.womenscientists", isActive: false))
        try legacy.save()
        return legacy
    }

    func testOwnedLegacyPackKeepsServingItsOldEmotions() throws {
        let legacy = try legacyContext()
        SeedManager.seedDatabaseIfNeeded(context: legacy)

        let stoic = try TestSupport.messages(packID: "pack.stoic", in: legacy).filter { ["a", "b"].contains($0.text) }
        XCTAssertEqual(stoic.count, 2)
        for m in stoic {
            XCTAssertEqual(m.categoryName, InterruptMessage.unlinkedCategory)
            XCTAssertEqual(Set(m.assignedEmotions), ["Stress", "Overthinking"])
            XCTAssertTrue(m.isActive, "Owners must not lose quotes on upgrade")
        }
    }

    func testLockedLegacyPackBecomesUnassigned() throws {
        let legacy = try legacyContext()
        SeedManager.seedDatabaseIfNeeded(context: legacy)

        let women = try TestSupport.messages(packID: "pack.womenscientists", in: legacy).first { $0.text == "c" }
        XCTAssertEqual(women?.categoryName, InterruptMessage.unlinkedCategory)
        XCTAssertTrue(women?.assignedEmotions.isEmpty == true)
    }

    func testMigrationLeavesFixedPacksAlone() throws {
        let legacy = try legacyContext()
        SeedManager.seedDatabaseIfNeeded(context: legacy)
        let core = try TestSupport.messages(packID: "core", in: legacy)
        XCTAssertGreaterThan(core.count, 0)
        XCTAssertTrue(core.allSatisfy { $0.categoryName != InterruptMessage.unlinkedCategory && $0.assignedEmotions.isEmpty })
    }

    func testMigrationIsIdempotentAndDoesNotOverwriteUserChoices() throws {
        let legacy = try legacyContext()
        SeedManager.seedDatabaseIfNeeded(context: legacy)
        PackAssignment.setAssignedEmotions(["Overthinking"], packID: "pack.stoic", context: legacy)

        SeedManager.seedDatabaseIfNeeded(context: legacy)
        SeedManager.seedDatabaseIfNeeded(context: legacy)

        let all = try legacy.fetch(FetchDescriptor<InterruptMessage>())
        XCTAssertEqual(PackAssignment.assignedEmotions(packID: "pack.stoic", in: all), ["Overthinking"])
    }
}
