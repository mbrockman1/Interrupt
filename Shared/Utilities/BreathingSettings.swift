//
//  BreathingSettings.swift
//  Interrupt
//
//  Created by Michael Brockman on 4/19/26.
//


import Foundation
import WatchConnectivity

class BreathingSettings {
    static let shared = BreathingSettings()
    private let store = UserDefaults(suiteName: DatabaseHelper.appGroupID)
    
    // Existing Settings
    var isIOSEnabled: Bool {
        get { store?.object(forKey: "breath_ios") as? Bool ?? true }
        set { store?.set(newValue, forKey: "breath_ios") }
    }
    
    var isWatchEnabled: Bool {
        get { store?.object(forKey: "breath_watch") as? Bool ?? true }
        set { store?.set(newValue, forKey: "breath_watch"); syncToWatch() }
    }
    
    // NEW: Haptic Toggles
    var hapticsIOS: Bool {
        get { store?.object(forKey: "haptics_ios") as? Bool ?? true }
        set { store?.set(newValue, forKey: "haptics_ios") }
    }
    
    var hapticsWatch: Bool {
        get { store?.object(forKey: "haptics_watch") as? Bool ?? true }
        set { store?.set(newValue, forKey: "haptics_watch"); syncToWatch() }
    }
    
    // NEW: Haptic Strength (1 = Light, 2 = Medium, 3 = Heavy)
    var hapticStrength: Int {
        get { store?.integer(forKey: "haptic_strength") == 0 ? 2 : store!.integer(forKey: "haptic_strength") }
        set { store?.set(newValue, forKey: "haptic_strength") }
    }
    
    func hasBreathing(for emotion: String) -> Bool {
        let list = store?.stringArray(forKey: "breath_emotions") ?? []
        return list.contains(emotion)
    }
    
    func toggleBreathing(for emotion: String) {
        var list = store?.stringArray(forKey: "breath_emotions") ?? []
        if list.contains(emotion) {
            list.removeAll { $0 == emotion }
        } else {
            list.append(emotion)
        }
        store?.set(list, forKey: "breath_emotions")
        syncToWatch()
    }
    
    // Updated Sync Payload
    private func syncToWatch() {
        let list = store?.stringArray(forKey: "breath_emotions") ?? []
        let watchEnabled = store?.object(forKey: "breath_watch") as? Bool ?? true
        let watchHaptics = store?.object(forKey: "haptics_watch") as? Bool ?? true
        
        // Grab the strength setting
        let strength = store?.integer(forKey: "haptic_strength") == 0 ? 2 : store!.integer(forKey: "haptic_strength")
        let payload: [String: Any] = ["breathing_settings": [
            "breath_emotions": list,
            "breath_watch": watchEnabled,
            "haptics_watch": watchHaptics,
            "haptic_strength": strength // ADDED: Send strength to the watch!
        ]]
        
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(payload, replyHandler: nil)
        } else {
            WCSession.default.transferUserInfo(payload)
        }
        }
}
