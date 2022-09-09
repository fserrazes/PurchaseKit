//  Created on 09.09.22
//  Copyright © 2022 Flavio Serrazes. All rights reserved.

import Foundation

public enum ProductType {
    case consumable
    case nonConsumable
}

public struct StoreProduct {
    let id: String
    let type: ProductType
    let displayName: String
    let description: String
    let price: Decimal
    let displayPrice: String
    let isFamilyShareable: Bool
    var isPurchased: Bool
}

public enum PurchasesError: Error {
    case unverified
    case failed(Error)
    
}
