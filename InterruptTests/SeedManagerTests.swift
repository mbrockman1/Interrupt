import XCTest
import SwiftData
@testable import Interrupt

@MainActor
final class SeedManagerTests: XCTestCase {
    var context: ModelContext!

    override func setUp() async throws {
        context = try TestSupport.makeContext()
    }

    func testFreshSeedCreatesDefaultTriggers() throws {
        SeedManager.seedDatabaseIfNeeded(context: context)
        let names = try context.fetch(FetchDescriptor<EmotionTrigger>()).map(\.name).sorted()
        XCTAssertEqual(names, ["Imposter Syndrome", "Overthinking", "Stress"])
    }

    func testFreshSeedCreatesAllPacks() throws {
        SeedManager.seedDatabaseIfNeeded(context: context)
        let ids = Set(try context.fetch(FetchDescriptor<ContentPack>()).map(\.id))
        XCTAssertEqual(ids, ["custom", "received", "core", "pack.imposter", "pack.stoic",
                             "pack.sciencefacts", "pack.scientists", "pack.womenscientists"])
    }

    func testPackOwnershipAndPremiumFlags() throws {
        SeedManager.seedDatabaseIfNeeded(context: context)
        let packs = try TestSupport.packs(in: context)
        for id in ["custom", "received", "core", "pack.imposter"] {
            XCTAssertTrue(packs[id]?.isPurchased == true, "\(id) should start owned")
        }
        XCTAssertFalse(packs["pack.stoic"]!.isPurchased)
        XCTAssertTrue(packs["pack.stoic"]!.isPremium)
        XCTAssertFalse(packs["pack.womenscientists"]!.isPurchased)
        XCTAssertTrue(packs["pack.womenscientists"]!.isPremium)
        for id in ["pack.sciencefacts", "pack.scientists"] {
            XCTAssertFalse(packs[id]!.isPurchased, "\(id) must be installed by the user")
            XCTAssertFalse(packs[id]!.isPremium, "\(id) is free")
        }
    }

    func testEveryNewPackHasTenMessages() throws {
        SeedManager.seedDatabaseIfNeeded(context: context)
        for id in ["pack.sciencefacts", "pack.scientists", "pack.womenscientists"] {
            XCTAssertEqual(try TestSupport.messages(packID: id, in: context).count, 10, id)
        }
    }

    func testLockedPackMessagesAreInactive() throws {
        SeedManager.seedDatabaseIfNeeded(context: context)
        for id in ["pack.stoic", "pack.sciencefacts", "pack.scientists", "pack.womenscientists"] {
            let messages = try TestSupport.messages(packID: id, in: context)
            XCTAssertFalse(messages.isEmpty, id)
            XCTAssertTrue(messages.allSatisfy { !$0.isActive }, "\(id) must not serve quotes while locked")
        }
    }

    func testOwnedPackMessagesAreActive() throws {
        SeedManager.seedDatabaseIfNeeded(context: context)
        for id in ["core", "pack.imposter"] {
            let messages = try TestSupport.messages(packID: id, in: context)
            XCTAssertFalse(messages.isEmpty, id)
            XCTAssertTrue(messages.allSatisfy(\.isActive), id)
        }
    }

    func testSeedingIsIdempotent() throws {
        SeedManager.seedDatabaseIfNeeded(context: context)
        let messageCount = try context.fetchCount(FetchDescriptor<InterruptMessage>())
        let packCount = try context.fetchCount(FetchDescriptor<ContentPack>())
        let triggerCount = try context.fetchCount(FetchDescriptor<EmotionTrigger>())

        SeedManager.seedDatabaseIfNeeded(context: context)
        SeedManager.seedDatabaseIfNeeded(context: context)

        XCTAssertEqual(try context.fetchCount(FetchDescriptor<InterruptMessage>()), messageCount)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<ContentPack>()), packCount)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<EmotionTrigger>()), triggerCount)
    }

    func testNewPacksReachExistingInstall() throws {
        // Simulate an older install: only the original packs exist.
        context.insert(EmotionTrigger(name: "Stress", isDefault: true))
        let core = ContentPack(id: "core", title: "The Essentials", subtitle: "", isPurchased: true)
        context.insert(core)
        context.insert(InterruptMessage(text: "old", typeRaw: "Affirmation", categoryName: "Stress", packID: "core"))
        try context.save()

        SeedManager.seedDatabaseIfNeeded(context: context)

        let packs = try TestSupport.packs(in: context)
        XCTAssertNotNil(packs["pack.sciencefacts"])
        XCTAssertNotNil(packs["pack.womenscientists"])
        XCTAssertEqual(try TestSupport.messages(packID: "core", in: context).first(where: { $0.text == "old" })?.text, "old")
        XCTAssertEqual(try TestSupport.messages(packID: "core", in: context).filter { $0.text == "old" }.count, 1)
    }

    func testSeedDeactivatesLeakedMessagesOfLockedPacks() throws {
        let stoic = ContentPack(id: "pack.stoic", title: "Stoic", subtitle: "", isPurchased: false, isPremium: true)
        context.insert(stoic)
        context.insert(InterruptMessage(text: "leaked", typeRaw: "Quote", categoryName: "Stress", packID: "pack.stoic", isActive: true))
        try context.save()

        SeedManager.seedDatabaseIfNeeded(context: context)

        let leaked = try TestSupport.messages(packID: "pack.stoic", in: context).first(where: { $0.text == "leaked" })
        XCTAssertEqual(leaked?.isActive, false)
    }

    func testSeedDoesNotDeactivatePurchasedPackMessages() throws {
        SeedManager.seedDatabaseIfNeeded(context: context)
        let stoic = try TestSupport.packs(in: context)["pack.stoic"]!
        StoreManager.shared.unlockPack(stoic, context: context)

        SeedManager.seedDatabaseIfNeeded(context: context)

        XCTAssertTrue(try TestSupport.messages(packID: "pack.stoic", in: context).allSatisfy(\.isActive))
    }

    func testUserDeactivatedOwnedMessageStaysInactive() throws {
        SeedManager.seedDatabaseIfNeeded(context: context)
        let msg = try TestSupport.messages(packID: "core", in: context).first!
        msg.isActive = false
        try context.save()

        SeedManager.seedDatabaseIfNeeded(context: context)

        XCTAssertFalse(msg.isActive)
    }
}
