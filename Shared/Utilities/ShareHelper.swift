//
//  SharedMessagePayload.swift
//  Interrupt
//
//  Created by Michael Brockman on 4/19/26.
//


import Foundation
import SwiftUI

// A lightweight structure to encode into the URL
struct SharedMessagePayload: Codable, Identifiable {
    var id: UUID { UUID() } // Automatically generated for the UI sheet
    let text: String
    let typeRaw: String
    let categoryName: String
    
    // Ensure the ID isn't required in the JSON
    enum CodingKeys: String, CodingKey {
        case text, typeRaw, categoryName
    }
}

class ShareHelper {
    // 1. Appends the data to your custom URL scheme
    static func createShareURL(for message: InterruptMessage) -> URL? {
        let payload = SharedMessagePayload(text: message.text, typeRaw: message.typeRaw, categoryName: message.categoryName)
        
        guard let data = try? JSONEncoder().encode(payload) else { return nil }
        let base64String = data.base64EncodedString()
        
        // Example: interrupt://import?payload=eyd0ZX...
        return URL(string: "interrupt://import?payload=\(base64String)")
    }
    
    // 2. Reads the URL and decodes the data back into a readable struct
    static func decode(from url: URL) -> SharedMessagePayload? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let payloadQuery = components.queryItems?.first(where: { $0.name == "payload" })?.value,
              let data = Data(base64Encoded: payloadQuery) else { return nil }
        
        return try? JSONDecoder().decode(SharedMessagePayload.self, from: data)
    }
}
