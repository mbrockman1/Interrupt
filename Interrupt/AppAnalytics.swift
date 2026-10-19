import Foundation
import FirebaseAnalytics

// Basic, anonymous usage counts only (iOS app target; watch/widget have no Firebase).
// Never pass emotion names, quote text, or note content: the Settings privacy copy promises
// that stays on the device.
enum AppAnalytics {
    static func log(_ name: String, _ parameters: [String: Any]? = nil) {
        Analytics.logEvent(name, parameters: parameters)
    }
}
