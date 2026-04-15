//
//  StoreManager.swift
//  Interrupt
//
//  Created by Michael Brockman on 4/13/26.
//
//
//
//import Foundation
//import StoreKit
//import SwiftData
//
//@MainActor
//class StoreManager: ObservableObject {
//    static let shared = StoreManager()
//    
//    // The exact IDs we will put into App Store Connect
//    let productIDs = ["pack.stoic", "pack.cbt"]
//    
//    @Published var products: [Product] = []
//    
//    init() {
//        Task {
//            await fetchProducts()
//        }
//    }
//
//    func fetchProducts() async {
//        do {
//            self.products = try await Product.products(for: productIDs)
//        } catch {
//            print("Failed to fetch products: \(error)")
//        }
//    }
//
//    func purchase(_ product: Product, pack: ContentPack, context: ModelContext) async {
//        do {
//            let result = try await product.purchase()
//            
//            switch result {
//            case .success(let verification):
//                let transaction = try verification.payloadValue
//                
//                // UNLOCK THE PACK IN SWIFTDATA
//                pack.isPurchased = true
//                try? context.save()
//                
//                // Notify the App Store that we handled the transaction
//                await transaction.finish()
//                print("✅ Purchase successful: \(pack.id)")
//                
//            case .userCancelled, .pending:
//                print("⚠️ Purchase cancelled or pending")
//            @unknown default:
//                break
//            }
//        } catch {
//            print("❌ Purchase failed: \(error)")
//        }
//    }
//}
