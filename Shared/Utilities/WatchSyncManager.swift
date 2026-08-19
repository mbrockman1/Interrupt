////
////  WatchSyncManager.swift
////  Interrupt
////
////  Created by Michael Brockman on 3/28/26.


import Foundation
import WatchConnectivity
import SwiftData

@MainActor
class WatchSyncManager: NSObject, WCSessionDelegate {
    static let shared = WatchSyncManager()
    var modelContext: ModelContext?
    
    func startSession() {
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    // --- SENDER: SYNC TRIGGERS (iPhone -> Watch) ---
    func syncTriggersToWatch(triggers: [EmotionTrigger]) {
        let triggerData = triggers.map { $0.toDictionary() }
        let payload = ["trigger_sync": triggerData]
        
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(payload, replyHandler: nil)
        } else {
            WCSession.default.transferUserInfo(payload)
        }
        print("📱 SyncManager: Beaming \(triggers.count) triggers to Watch...")
    }

    // --- SENDER: SYNC LIBRARY (iPhone -> Watch) ---
    func syncLibraryToWatch(messages:[InterruptMessage]) {
        let messageData = messages.map { $0.toDictionary() }
        let payload = ["library_sync": messageData]
        
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(payload, replyHandler: nil)
        } else {
            WCSession.default.transferUserInfo(payload)
        }
    }

    // --- SENDER: ANALYTICS LOG (Watch -> iPhone) ---
    func sendLogToPhone(categoryName: String) {
        let payload = ["log_category": categoryName, "timestamp": Date()] as [String : Any]
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(payload, replyHandler: nil)
        } else {
            WCSession.default.transferUserInfo(payload)
        }
    }

    // --- RECEIVER ---
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) { handleIncomingPayload(message) }
    func session(_ session: WCSession, didReceiveUserInfo userInfo:[String : Any] = [:]) { handleIncomingPayload(userInfo) }

    private func handleIncomingPayload(_ payload: [String: Any]) {
        guard let context = modelContext else { return }
        
        
        
        // 1. Receive Analytics (FIXED: Now reads the exact historical timestamp!)
        if let category = payload["log_category"] as? String {
            // Extract the time you actually tapped the watch, fallback to current time if missing
            let exactTime = payload["timestamp"] as? Date ?? Date()
            
            DispatchQueue.main.async {
                // Pass the exactTime into the log so your charts are 100% accurate
                context.insert(InterruptLog(timestamp: exactTime, categoryName: category))
                try? context.save()
                print("📱 Received Log: \(category) at \(exactTime)")
            }
        }
        
        // 2. Receive Library Sync
        if let libraryData = payload["library_sync"] as? [[String: Any]] {
            DispatchQueue.main.async { self.processLibrarySync(libraryData, context: context) }
        }
        
        // 3. Receive Trigger Sync
        if let triggerData = payload["trigger_sync"] as? [[String: Any]] {
            DispatchQueue.main.async { self.processTriggerSync(triggerData, context: context) }
        }
        if let settings = payload["breathing_settings"] as? [String: Any] {
            if let emotions = settings["breath_emotions"] as? [String] {
                UserDefaults(suiteName: DatabaseHelper.appGroupID)?.set(emotions, forKey: "breath_emotions")
            }
            if let watchEnabled = settings["breath_watch"] as? Bool {
                UserDefaults(suiteName: DatabaseHelper.appGroupID)?.set(watchEnabled, forKey: "breath_watch")
            }
            // ADD THIS LINE:
            if let watchHaptics = settings["haptics_watch"] as? Bool {
                UserDefaults(suiteName: DatabaseHelper.appGroupID)?.set(watchHaptics, forKey: "haptics_watch")
            }
            
            if let strength = settings["haptic_strength"] as? Int {
                            UserDefaults(suiteName: DatabaseHelper.appGroupID)?.set(strength, forKey: "haptic_strength")
                        }
            print("⌚️ Watch: Breathing settings synced successfully!")
        }
    }

    // Processes the incoming Triggers on the Watch
    private func processTriggerSync(_ data: [[String: Any]], context: ModelContext) {
            // Ensure all database work happens on the main thread for UI consistency
            DispatchQueue.main.async {
                print("⌚️ Watch: Processing Trigger Sync...")
                let incomingIds = data.compactMap { $0["id"] as? String }
                
                for dict in data {
                    if let incoming = EmotionTrigger.fromDictionary(dict) {
                        let id = incoming.id
                        let fetch = FetchDescriptor<EmotionTrigger>(predicate: #Predicate { $0.id == id })
                        
                        if let existing = (try? context.fetch(fetch))?.first {
                            // Update the hidden status and name
                            existing.name = incoming.name
                            existing.isHidden = incoming.isHidden
                            existing.isDefault = incoming.isDefault
                        } else {
                            context.insert(incoming)
                        }
                    }
                }
                
                // Delete logic for custom emotions
                if let allExisting = try? context.fetch(FetchDescriptor<EmotionTrigger>()) {
                    for existing in allExisting {
                        if !incomingIds.contains(existing.id.uuidString) {
                            context.delete(existing)
                        }
                    }
                }
                
                try? context.save()
                print("⌚️ Watch: UI Updated with new Hidden/Custom triggers.")
            }
        }

    // Processes incoming Library on the Watch
    private func processLibrarySync(_ data: [[String: Any]], context: ModelContext) {
        for dict in data {
            if let incomingMsg = InterruptMessage.fromDictionary(dict) {
                let id = incomingMsg.id
                let fetch = FetchDescriptor<InterruptMessage>(predicate: #Predicate { $0.id == id })
                if let existing = (try? context.fetch(fetch))?.first {
                    existing.text = incomingMsg.text
                    existing.isActive = incomingMsg.isActive
                    existing.categoryName = incomingMsg.categoryName
                } else {
                    context.insert(incomingMsg)
                }
            }
        }
        try? context.save()
    }

    func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {}
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { WCSession.default.activate() }
    #endif
}
