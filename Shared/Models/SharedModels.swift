import Foundation
import SwiftData

@Model
final class EmotionTrigger {
    var id: UUID = UUID()
    var name: String = ""
    var isDefault: Bool = false
    var isHidden: Bool = false
    
    init(id: UUID = UUID(), name: String, isDefault: Bool = false, isHidden: Bool = false) {
        self.id = id
        self.name = name
        self.isDefault = isDefault
        self.isHidden = isHidden
    }
    
    // NEW: Pack for Bluetooth
    func toDictionary() -> [String: Any] {
        return[
            "id": id.uuidString,
            "name": name,
            "isDefault": isDefault,
            "isHidden": isHidden
        ]
    }
    
    // NEW: Unpack from Bluetooth
    static func fromDictionary(_ dict: [String: Any]) -> EmotionTrigger? {
        guard let idString = dict["id"] as? String,
              let id = UUID(uuidString: idString),
              let name = dict["name"] as? String,
              let isDefault = dict["isDefault"] as? Bool,
              let isHidden = dict["isHidden"] as? Bool else { return nil }
        
        return EmotionTrigger(id: id, name: name, isDefault: isDefault, isHidden: isHidden)
    }
}


@Model
final class ContentPack {
    @Attribute(.unique) var id: String = "" // Keep id as String for StoreKit IDs
    var title: String = ""
    var subtitle: String = ""
    var isPurchased: Bool = false
    var isPremium: Bool = false
    
    // Relationship: A pack "owns" many messages
//    @Relationship(deleteRule: .cascade, inverse: \InterruptMessage.pack)
    var messages: [InterruptMessage] = []
    
    init(id: String, title: String, subtitle: String, isPurchased: Bool = false, isPremium: Bool = false) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.isPurchased = isPurchased
        self.isPremium = isPremium
    }
}

@Model
final class InterruptMessage {
    var id: UUID = UUID()
    var text: String = ""
    var typeRaw: String = "Affirmation"
    var categoryName: String = "Stress"
    var isActive: Bool = true

    // NEW: Associates this message with a specific pack
    var packID: String = "core"

    init(id: UUID = UUID(), text: String, typeRaw: String, categoryName: String, packID: String = "core", isActive: Bool = true) {
        self.id = id
        self.text = text
        self.typeRaw = typeRaw
        self.categoryName = categoryName
        self.packID = packID
        self.isActive = isActive
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id.uuidString,
            "text": text,
            "typeRaw": typeRaw,
            "categoryName": categoryName,
            "packID": packID,
            "isActive": isActive
        ]
    }
    
    // Creates a Message from a Dictionary received from the iPhone
    static func fromDictionary(_ dict: [String: Any]) -> InterruptMessage? {
        guard let idString = dict["id"] as? String,
              let id = UUID(uuidString: idString),
              let text = dict["text"] as? String,
              let typeRaw = dict["typeRaw"] as? String,
              let categoryName = dict["categoryName"] as? String,
              let packID = dict["packID"] as? String,
              let isActive = dict["isActive"] as? Bool else { return nil }
        
        return InterruptMessage(id: id, text: text, typeRaw: typeRaw, categoryName: categoryName, packID: packID, isActive: isActive)
    }
}

@Model
final class InterruptLog {
    var id: UUID = UUID()
    var timestamp: Date = Date()
    var categoryName: String = "Stress"
    
    init(id: UUID = UUID(), timestamp: Date = Date(), categoryName: String) {
        self.id = id
        self.timestamp = timestamp
        self.categoryName = categoryName
    }
}
