//  Created on 09.09.22
//  Copyright © 2022 Flavio Serrazes. All rights reserved.

import Foundation

public protocol PurchasesDelegate: AnyObject {
    func didFinishedPurchases(product: StoreProduct)
}
