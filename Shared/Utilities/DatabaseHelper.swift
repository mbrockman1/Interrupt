//
//  DatabaseHelper.swift
//  Interrupt
//
//  Created by Michael Brockman on 4/13/26.
//
import Foundation
import SwiftData

@MainActor
public struct DatabaseHelper {
    // ⚠️ DOUBLE CHECK THIS STRING matches your Signing & Capabilities tab EXACTLY
    static let appGroupID = "group.com.mbapps.interrupt"
    
    public static let schema = Schema([
        EmotionTrigger.self,
        ContentPack.self,
        InterruptMessage.self,
        InterruptLog.self
    ])

    public static func getContainer(forWidget: Bool = false) -> ModelContainer {
        guard let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            fatalError("Could not find App Group: \(appGroupID)")
        }
        
        let url = groupURL.appendingPathComponent("Interrupt.sqlite")
        
        // Widgets MUST use allowsSave: false to avoid database locking crashes
        let config = ModelConfiguration(
            url: url,
            allowsSave: !forWidget, 
            cloudKitDatabase: .none 
        )

        do {
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("DatabaseHelper: Failed to create container: \(error)")
        }
    }
}

