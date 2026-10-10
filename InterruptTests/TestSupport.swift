import Foundation
import SwiftData
@testable import Interrupt

enum TestSupport {
    @MainActor
    static func makeContext() throws -> ModelContext {
        let schema = Schema([EmotionTrigger.self, ContentPack.self, InterruptMessage.self, InterruptLog.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try ModelContainer(for: schema, configurations: [config])
        retained.append(container)
        return container.mainContext
    }

    @MainActor private static var retained: [ModelContainer] = []

    @MainActor
    static func packs(in context: ModelContext) throws -> [String: ContentPack] {
        Dictionary(uniqueKeysWithValues: try context.fetch(FetchDescriptor<ContentPack>()).map { ($0.id, $0) })
    }

    @MainActor
    static func messages(packID: String, in context: ModelContext) throws -> [InterruptMessage] {
        try context.fetch(FetchDescriptor<InterruptMessage>()).filter { $0.packID == packID }
    }
}
