//  Created on 09.09.22
//  Copyright © 2022 Flavio Serrazes. All rights reserved.

import Foundation

/// Description
/// ``Purchases`` is the entry point for Purchasekit.framework.
/// - Warning: Only one instance of Purchases should be instantiated at a time! Use a configure method to let the
/// framework handle the singleton instance for you.
public final class Purchases: NSObject {

    /// Returns the already configured instance of ``Purchases``.
    /// - Warning: this method will crash with `fatalError` if ``Purchases`` has not been initialized through
    /// ``configure(with identifiers:)`` or one of its overloads. If there's a chance that may have not happened yet,
    /// you can use ``isConfigured`` to check if it's safe to call.
    public static var shared: Purchases {
        guard let purchases = Self.purchases.value else {
            fatalError("Purchases has not been configured. Please call Purchases.configure()")
        }
        return purchases
    }

    private static let purchases: Atomic<Purchases?> = .init(nil)
    
    /// Returns `true` if PurchaseKit has already been initialized through ``configure(with identifiers:)``
    /// or one of is overloads.
    public static var isConfigured: Bool { Self.purchases.value != nil }
    
    private var identifiers: [String] = []
    
    private init(identifiers: [String]) {
        Self.purchases.modify {
            $0?.identifiers = identifiers
        }
        super.init()
    }
    
    /// Configures an instance of the Purchases SDK with a specified identifiers keys
    /// - Parameter identifiers: Products ids defined in App Store Connect.
    /// - Returns: An instantiated ``Purchases`` object that has been set as a singleton.
    @discardableResult static func configure(with identifiers: [String]) -> Purchases {
        let purchases = Purchases(identifiers: identifiers)
        setDefaultInstance(purchases)
        return purchases
    }
    
    private static func setDefaultInstance(_ purchases: Purchases) {
        self.purchases.modify { currentInstance in
            if currentInstance != nil {
                print("configure.purchase_instance_already_set")
            }
            currentInstance = purchases
        }
    }
}

/*
 
 /**
  * Indicates whether the user is allowed to make payments.
  * [More information on when this might be `false` here](https://rev.cat/can-make-payments-apple)
  */
 @objc public static func canMakePayments() -> Bool { SKPaymentQueue.canMakePayments() }
 
 static func clearSingleton() {
     Self.purchases.value = nil
 }
 deinit {
     self.privateDelegate = nil
     
 }
 func checkInstance(){
     print("\(self) \(#function) - Count \(1)")
 }
 
 public protocol PurchasesDelegate: NSObjectProtocol {}
 
 /**
  * Delegate for ``Purchases`` instance. The delegate is responsible for handling promotional product purchases and
  * changes to customer information.
  * - Note: this is not thread-safe.
  */
 public var delegate: PurchasesDelegate? {
     get { self.privateDelegate }
     set {
         guard newValue !== self.privateDelegate else {
             print("purchase.purchases_delegate_set_multiple_times")
             return
         }

         if newValue == nil {
             print("purchase.purchases_delegate_set_to_nil")
         }

         self.privateDelegate = newValue
         print("configure.delegate_set")

         // Sends cached customer info (if exists) to delegate as latest
         // customer info may have already been observed and sent by the monitor
//            self.sendCachedCustomerInfoToDelegateIfExists()
     }
 }

 private weak var privateDelegate: PurchasesDelegate?
 */
