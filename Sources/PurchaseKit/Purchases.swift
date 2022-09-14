//  Created on 09.09.22
//  Copyright © 2022 Flavio Serrazes. All rights reserved.

import Foundation
import StoreKit

/// Description
/// ``Purchases`` is the entry point for Purchasekit.framework.
/// - Warning: Only one instance of Purchases should be instantiated at a time! Use a configure method to let the
/// framework handle the singleton instance for you.
public final class Purchases: PurchasesProtocol {

    /// Returns the already configured instance of ``Purchases``.
    /// - Warning: this method will crash with `fatalError` if ``Purchases`` has not been initialized through
    /// ``configure(with identifiers:)`` or one of its overloads.
    public static var shared: Purchases {
        if let initializedShared = purchases {
            return initializedShared
        }
        fatalError("Purchases has not been configured. Please call Purchases.configure()")
    }

    private static var purchases: Purchases?
    private (set) var updateListenerTask: Task<Void, Error>?

    private var identifiers: [String]
    public weak var delegate: PurchasesDelegate?

    private init(identifiers: [String]) {
        self.identifiers = identifiers

        // Start a transaction listener
        updateListenerTask = listenForTransactions()
    }

    deinit {
        delegate = nil
        updateListenerTask?.cancel()
    }

    /// Configures an instance of the Purchases SDK with a specified identifiers keys
    /// - Parameter identifiers: A set of product identifiers for in-app purchases setup via App Store Connect.
    /// [AppStoreConnect](https://appstoreconnect.apple.com/)
    /// - Returns: An instantiated ``Purchases`` object that has been set as a singleton.
    @discardableResult public class func configure(with identifiers: [String]) -> Purchases {
        return Purchases(identifiers: identifiers)
    }
}

// MARK: Purchasing

extension Purchases {
    /// Indicates whether the user is allowed to make payments.
    ///
    /// This value is true if the user can authorize payments in the App Store; otherwise false.
    /// The value of canMakePayments is false when users set content and privacy controls to limit
    /// a child's ability to purchase content.
    public static func canMakePayments() -> Bool {
        return SKPaymentQueue.canMakePayments()
    }

    /// Fetches the ``StoreProduct``s configured in ``Purchases/configure(with:)``.
    ///
    /// Purchases status will be send through the delegate later.
    /// - Note: `Result` may be return without ``StoreProduct`` s that you are expecting. This is usually caused by
    /// AppleStoreConnect configuration errors. Ensure your IAPs have the "Ready to Submit" status in AppleStoreConnect.
    /// - Returns: List of Consumable and NonConsumable StoreProduct or ``PurchasesError`` with description.
    public func requestProducts() async -> Result<[StoreProduct], PurchasesError> {
        do {
            // Request products from the App Store using identifiers.
            let storeProducts = try await Product.products(for: identifiers)

            var products: [StoreProduct] = []
            for product in storeProducts {
                if product.type == .consumable || product.type == .nonConsumable {
                    products.append(mapper(product: product))
                }
            }
            // Purchases status will be send through the delegate
            Task.detached { await self.updateCustomerProductStatus() }

            return .success(products)
        } catch {
            print("Failed product request from the App Store server: \(error)")
            return .failure(.failed(error))
        }
    }

    /// Initiates a purchase of a ``StoreProduct``.
    ///
    /// - Important: Call this method when a user has decided to purchase a product.
    /// Only call this in direct response to user input.
    ///
    /// - Note: You do not need to finish the transaction yourself, ``Purchases`` will handle this for you.
    /// - Parameter productId: The product identifier defined in the for in-app which user intends to purchase.
    /// - Returns: Returns if transaction completes with success or not.
    public func purchase(productId: String) async throws -> Bool {
        let storeProduct = try await Product.products(for: [productId])
        if let product = storeProduct.first {
            // Begin purchasing the 'Product' the user selects.
            let result = try await product.purchase()

            switch result {
                case .success(let verification):
                    // If transaction isn't verified, this function rethrows the verification error.
                    let transaction = try checkVerified(verification)

                    // The transaction is verified. Deliver content to the user.
                    assert(product.id == transaction.productID)
                    await refreshPurchasedProductStatus(product: product)

                    // Always finish a transaction.
                    await transaction.finish()
                    return true
                default:
                    break
            }
        }
        return false
    }

    /// This call displays a system prompt that asks users to authenticate with their App Store credentials.
    ///
    /// Call this function only in response to an explicit user action, such as tapping a button.
    public func restore() async {
        try? await AppStore.sync()
    }

}

// MARK: - Private Helpers

extension Purchases {
    private func mapper(product: Product, isPurchased: Bool = false) -> StoreProduct {
        let type: ProductType = product.type == .consumable ? .consumable : .nonConsumable
        // swiftlint: disable line_length
        let product = StoreProduct(id: product.id, type: type, displayName: product.displayName, description: product.description, price: product.price, displayPrice: product.displayPrice, isFamilyShareable: product.isFamilyShareable, isPurchased: isPurchased)

        return product
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        // Check whether the JWS passes StoreKit verification.
        switch result {
            case .unverified:
                // StoreKit parses the JWS, but it fails verification.
                throw PurchasesError.unverified
            case .verified(let safe):
                // The result is verified. Return the unwrapped value.
                return safe
        }
    }

    private func updateCustomerProductStatus() async {
        // Iterate through all products the user's purchased.
        // Consumable don't apper int the current entitlements.
        for await result in Transaction.currentEntitlements {

            // Check whether the transaction is verified. If it isn't, this function throws the verification error.
            if let transaction = try? checkVerified(result) {
                if let product = (try? await Product.products(for: [transaction.productID]))?.first {
                    await refreshPurchasedProductStatus(product: product)
                }
            }
        }
    }

    private func refreshPurchasedProductStatus(product: Product) async {
        var storeProduct = mapper(product: product)
        storeProduct.isPurchased = true

        delegate?.didFinishedPurchases(product: storeProduct)
    }

    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            // Iterate through any transactions that don't come from a direct call to `purchase()`.
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)

                    // Deliver products to the user.
                    await self.updateCustomerProductStatus()

                    // Always finish a transaction.
                    await transaction.finish()
                } catch {
                    // StoreKit has a transaction that fails verification. Don't deliver content to the user.
                    print("Transaction failed verification")
                }
            }
        }
    }
}
