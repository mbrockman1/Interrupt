import XCTest
import SwiftData
@testable import Interrupt

@MainActor
final class UnlockAndSelectionTests: XCTestCase {
    var context: ModelContext!

    override func setUp() async throws {
        context = try TestSupport.makeContext()
        SeedManager.seedDatabaseIfNeeded(context: context)
    }

    func testUnlockMarksPackOwnedAndActivatesItsMessages() throws {
        let pack = try TestSupport.packs(in: context)["pack.sciencefacts"]!
        StoreManager.shared.unlockPack(pack, context: context)

        XCTAssertTrue(pack.isPurchased)
        XCTAssertTrue(try TestSupport.messages(packID: "pack.sciencefacts", in: context).allSatisfy(\.isActive))
    }

    func testUnlockOnlyAffectsThatPack() throws {
        let pack = try TestSupport.packs(in: context)["pack.sciencefacts"]!
        StoreManager.shared.unlockPack(pack, context: context)

        for id in ["pack.scientists", "pack.stoic", "pack.womenscientists"] {
            XCTAssertTrue(try TestSupport.messages(packID: id, in: context).allSatisfy { !$0.isActive }, id)
            XCTAssertFalse(try TestSupport.packs(in: context)[id]!.isPurchased, id)
        }
    }

    func testUnlockIsIdempotent() throws {
        let pack = try TestSupport.packs(in: context)["pack.scientists"]!
        StoreManager.shared.unlockPack(pack, context: context)
        let before = try context.fetchCount(FetchDescriptor<InterruptMessage>())
        StoreManager.shared.unlockPack(pack, context: context)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<InterruptMessage>()), before)
        XCTAssertTrue(pack.isPurchased)
    }

    func testUnlockSurvivesReseed() throws {
        let pack = try TestSupport.packs(in: context)["pack.womenscientists"]!
        StoreManager.shared.unlockPack(pack, context: context)
        SeedManager.seedDatabaseIfNeeded(context: context)
        XCTAssertTrue(pack.isPurchased)
        XCTAssertTrue(try TestSupport.messages(packID: "pack.womenscientists", in: context).allSatisfy(\.isActive))
    }

    func testLockedPacksAreNeverServedByMessageStore() throws {
        let locked: Set<String> = ["pack.stoic", "pack.sciencefacts", "pack.scientists", "pack.womenscientists"]
        for category in ["Stress", "Overthinking", "Imposter Syndrome"] {
            for _ in 0..<200 {
                let served = MessageStore.shared.getMessage(for: category, context: context)
                XCTAssertFalse(locked.contains(served.packID), "Locked quote served from \(served.packID): \(served.text)")
            }
        }
    }

    func testInstalledPackBecomesServable() throws {
        let pack = try TestSupport.packs(in: context)["pack.sciencefacts"]!
        StoreManager.shared.unlockPack(pack, context: context)
        let factTexts = Set(try TestSupport.messages(packID: "pack.sciencefacts", in: context).map(\.text))

        var servedFact = false
        for _ in 0..<2000 where !servedFact {
            for category in ["Stress", "Overthinking", "Imposter Syndrome"] {
                if factTexts.contains(MessageStore.shared.getMessage(for: category, context: context).text) { servedFact = true }
            }
        }
        XCTAssertTrue(servedFact)
    }

    func testMessageStoreFallsBackWhenNothingActive() throws {
        for m in try context.fetch(FetchDescriptor<InterruptMessage>()) { m.isActive = false }
        let served = MessageStore.shared.getMessage(for: "Stress", context: context)
        XCTAssertFalse(served.text.isEmpty)
    }
}
