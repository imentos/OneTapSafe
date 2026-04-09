//
//  SubscriptionManager.swift
//  OneTapSafe
//
//  Created by OneTap OK on 2/13/26.
//

import Foundation
import StoreKit
import Combine

/// Manages in-app purchases and subscription status using StoreKit 2
@MainActor
final class SubscriptionManager: ObservableObject {
    
    static let shared = SubscriptionManager()
    
    // MARK: - Product IDs
    
    enum ProductID: String, CaseIterable {
        case monthly = "com.onetapok.monthly"
        case annual = "com.onetapok.annual"
        case lifetime = "com.onetapok.lifetime"
        
        var displayName: String {
            switch self {
            case .monthly: return "Monthly"
            case .annual: return "Annual"
            case .lifetime: return "Lifetime"
            }
        }
    }
    
    // MARK: - Published Properties
    
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs: Set<String> = []
    @Published private(set) var isLoading = false
    
    /// Whether the user has an active Pro subscription or lifetime purchase
    var isPro: Bool {
        !purchasedProductIDs.isEmpty
    }
    
    /// Maximum number of contacts allowed
    var maxContacts: Int {
        isPro ? Int.max : 1
    }
    
    private var updateListenerTask: Task<Void, Never>?
    
    // MARK: - Initialization
    
    private init() {
        // Start listening for transaction updates
        updateListenerTask = listenForTransactions()
        
        // Load products and check subscription status
        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Product Loading
    
    /// Load available products from the App Store
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let productIDs = ProductID.allCases.map { $0.rawValue }
            let loadedProducts = try await Product.products(for: productIDs)
            
            // Sort products: monthly, annual, lifetime
            self.products = loadedProducts.sorted { product1, product2 in
                let order = [ProductID.monthly.rawValue, ProductID.annual.rawValue, ProductID.lifetime.rawValue]
                let index1 = order.firstIndex(of: product1.id) ?? Int.max
                let index2 = order.firstIndex(of: product2.id) ?? Int.max
                return index1 < index2
            }
            
            print("✅ Loaded \(products.count) products")
        } catch {
            print("❌ Failed to load products: \(error)")
        }
    }
    
    // MARK: - Purchase
    
    /// Purchase a product
    func purchase(_ product: Product) async throws -> Bool {
        print("🛒 Attempting to purchase: \(product.displayName)")
        
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            // Verify the transaction
            let transaction = try checkVerified(verification)
            
            // Update subscription status
            await updateSubscriptionStatus()
            
            // Finish the transaction
            await transaction.finish()
            
            print("✅ Purchase successful: \(product.displayName)")
            return true
            
        case .userCancelled:
            print("⚠️ User cancelled purchase")
            return false
            
        case .pending:
            print("⏳ Purchase pending approval")
            return false
            
        @unknown default:
            print("❌ Unknown purchase result")
            return false
        }
    }
    
    // MARK: - Restore Purchases
    
    /// Restore previously purchased products
    func restorePurchases() async {
        print("🔄 Restoring purchases...")
        
        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
            print("✅ Purchases restored")
        } catch {
            print("❌ Failed to restore purchases: \(error)")
        }
    }
    
    // MARK: - Subscription Status
    
    /// Update the current subscription status
    func updateSubscriptionStatus() async {
        var activePurchases: Set<String> = []
        
        // Check all transactions
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                // Add to active purchases if valid
                if transaction.revocationDate == nil {
                    activePurchases.insert(transaction.productID)
                }
            } catch {
                print("❌ Transaction verification failed: \(error)")
            }
        }
        
        purchasedProductIDs = activePurchases
        
        if isPro {
            print("✅ User is Pro")
        } else {
            print("ℹ️ User is on free tier")
        }
    }
    
    // MARK: - Transaction Updates
    
    /// Listen for transaction updates (purchases, renewals, expirations)
    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { @MainActor in
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    
                    // Update subscription status on the main actor
                    await self.updateSubscriptionStatus()
                    
                    // Finish the transaction
                    await transaction.finish()
                } catch {
                    print("❌ Transaction update failed: \(error)")
                }
            }
        }
    }
    
    // MARK: - Verification
    
    /// Verify a transaction to ensure it's legitimate
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - Helper Methods
    
    /// Get product by ID
    func product(for productID: ProductID) -> Product? {
        products.first { $0.id == productID.rawValue }
    }
    
    /// Check if user can add more contacts
    func canAddContact(currentCount: Int) -> Bool {
        currentCount < maxContacts
    }
}

// MARK: - Errors

enum SubscriptionError: LocalizedError {
    case failedVerification
    case productNotFound
    case purchaseFailed
    
    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "Purchase verification failed"
        case .productNotFound:
            return "Product not found"
        case .purchaseFailed:
            return "Purchase failed"
        }
    }
}
