import Foundation
import StoreKit
import SwiftData
import Combine
#if FIREBASE_ENABLED
import FirebaseAnalytics
#endif

@MainActor
class StoreManager: ObservableObject {
    static let shared = StoreManager()
    
    // The Product IDs matching your database and StoreKit file
    let productIDs = ["pack.stoic"]
    
    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    
    init() {
        Task {
            await fetchProducts()
            await updatePurchasedStatus()
        }
    }
    
    func fetchProducts() async {
        do {
            let fetchedProducts = try await Product.products(for: productIDs)
            self.products = fetchedProducts
        } catch {
            print("StoreKit: Failed to fetch products - \(error)")
        }
    }
    
    // Handles the actual purchase
    func purchase(_ product: Product, pack: ContentPack, context: ModelContext) async {
        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                // Verify the transaction is cryptographically signed by Apple
                guard case .verified(let transaction) = verification else {
                    #if FIREBASE_ENABLED
                    Analytics.logEvent("purchase_verification_failed", parameters: ["pack": pack.id])
                    #endif
                    return
                }

                // UNLOCK IN THE DATABASE!
                pack.isPurchased = true
                do {
                    try context.save()
                } catch {
                    #if FIREBASE_ENABLED
                    Analytics.logEvent("purchase_save_error", parameters: ["pack": pack.id])
                    #endif
                    print("❌ Failed to save purchase: \(error)")
                }

                // Sync the unlock to the Apple Watch
                if let allMessages = try? context.fetch(FetchDescriptor<InterruptMessage>()) {
                    WatchSyncManager.shared.syncLibraryToWatch(messages: allMessages)
                }

                // Tell Apple we delivered the content
                await transaction.finish()

                // Update local UI state
                purchasedProductIDs.insert(product.id)

                // Track successful purchase
                #if FIREBASE_ENABLED
                Analytics.logEvent("purchase_completed", parameters: [
                    "pack_id": pack.id,
                    "product_id": product.id,
                    "price": NSNumber(value: Double(truncating: product.price as NSDecimalNumber))
                ])
                #endif

                print("✅ StoreKit: Purchase successful for \(pack.id)")

            case .userCancelled:
                #if FIREBASE_ENABLED
                Analytics.logEvent("purchase_cancelled", parameters: ["pack": pack.id])
                #endif
                print("⚠️ StoreKit: Purchase cancelled")
            case .pending:
                #if FIREBASE_ENABLED
                Analytics.logEvent("purchase_pending", parameters: ["pack": pack.id])
                #endif
                print("⚠️ StoreKit: Purchase pending")
            @unknown default:
                break
            }
        } catch {
            #if FIREBASE_ENABLED
            Analytics.logEvent("purchase_error", parameters: [
                "pack": pack.id,
                "error": error.localizedDescription
            ])
            #endif
            print("❌ StoreKit: Purchase failed - \(error)")
        }
    }
    
    // Restores purchases if the user deletes the app or gets a new phone
    func updatePurchasedStatus() async {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            purchasedProductIDs.insert(transaction.productID)
        }
    }
    
    func updatePurchasedStatus(context: ModelContext) async {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            
            // 1. If Apple says they own it, find the pack and unlock it
            let productID = transaction.productID
            let fetch = FetchDescriptor<ContentPack>(predicate: #Predicate { $0.id == productID })
            
            if let pack = (try? context.fetch(fetch))?.first {
                pack.isPurchased = true
            }
        }
        
        // 2. Save the database
        try? context.save()
        
        // 3. Tell the Apple Watch to unlock the quotes too!
        if let allMessages = try? context.fetch(FetchDescriptor<InterruptMessage>()) {
            WatchSyncManager.shared.syncLibraryToWatch(messages: allMessages)
        }
    }
    
    // Call this function when the user taps "Restore Purchases"
    func restorePurchases(context: ModelContext) async {
        // Ask Apple for all previous purchases
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            
            // Find the pack and unlock it
            let packID = transaction.productID
            let fetch = FetchDescriptor<ContentPack>(predicate: #Predicate { $0.id == packID })
            
            if let pack = (try? context.fetch(fetch))?.first {
                pack.isPurchased = true
            }
        }
        try? context.save()
        print("✅ Purchases restored from Apple!")
    }
}
