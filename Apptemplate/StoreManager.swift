//
//  StoreManager.swift
//  Apptemplate
//
//  Created by Mohamed Abdelmagid on 8/19/25.
//

import Foundation
import StoreKit

@MainActor
final class StoreManager: ObservableObject {
    @Published var products: [Product] = []
    @Published var isSubscribed: Bool = false
    @Published var purchaseState: PurchaseState = .idle
    
    private var updateListenerTask: Task<Void, Never>?
    
    enum PurchaseState: Equatable {
        case idle
        case purchasing
        case purchased
        case failed(Error)
        
        static func == (lhs: PurchaseState, rhs: PurchaseState) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.purchasing, .purchasing), (.purchased, .purchased):
                return true
            case (.failed(_), .failed(_)):
                return true
            default:
                return false
            }
        }
    }
    
    private let productIds = [
        "template_weekly",
        "template_lifetime"
    ]
    
    init() {
        updateListenerTask = listenForTransactions()
        
        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    func loadProducts() async {
        do {
            products = try await Product.products(for: productIds)
        } catch {
            print("Failed to load products: \(error)")
        }
    }
    
    func purchase(_ product: Product) async {
        purchaseState = .purchasing
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    purchaseState = .purchased
                    await updateSubscriptionStatus()
                case .unverified:
                    purchaseState = .failed(StoreError.verificationFailed)
                }
            case .userCancelled:
                purchaseState = .idle
            case .pending:
                purchaseState = .idle
            @unknown default:
                purchaseState = .idle
            }
        } catch {
            purchaseState = .failed(error)
        }
    }
    
    func updateSubscriptionStatus() async {
        var hasActiveSubscription = false
        
        for await result in Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                if transaction.productID == "template_weekly" || transaction.productID == "template_lifetime" {
                    hasActiveSubscription = true
                    break
                }
            case .unverified:
                continue
            }
        }
        
        isSubscribed = hasActiveSubscription
    }
    
    private func listenForTransactions() -> Task<Void, Never> {
        return Task.detached {
            for await result in Transaction.updates {
                switch result {
                case .verified(let transaction):
                    await transaction.finish()
                    await self.updateSubscriptionStatus()
                case .unverified:
                    continue
                }
            }
        }
    }
    
    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
        } catch {
            print("Failed to restore purchases: \(error)")
        }
    }
}

enum StoreError: LocalizedError {
    case verificationFailed
    
    var errorDescription: String? {
        switch self {
        case .verificationFailed:
            return "Transaction verification failed"
        }
    }
}