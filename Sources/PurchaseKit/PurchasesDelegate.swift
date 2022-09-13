//  Created on 09.09.22
//  Copyright © 2022 Flavio Serrazes. All rights reserved.

import Foundation

/// Delegate for ``Purchases`` instance. The delegate is responsible for handling purchase finish status.
public protocol PurchasesDelegate: AnyObject {
    func didFinishedPurchases(product: StoreProduct)
}
