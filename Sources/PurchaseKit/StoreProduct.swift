//  Created on 09.09.22
//  Copyright © 2022 Flavio Serrazes. All rights reserved.

import Foundation

public enum ProductType {
    case consumable
    case nonConsumable
}

public struct StoreProduct {
    public let id: String
    public let type: ProductType
    public let displayName: String
    public let description: String
    public let price: Decimal
    public let displayPrice: String
    public let isFamilyShareable: Bool
    public var isPurchased: Bool

    public init(id: String, type: ProductType, displayName: String, description: String, price: Decimal,
                displayPrice: String, isFamilyShareable: Bool, isPurchased: Bool) {
        self.id = id
        self.type = type
        self.displayName = displayName
        self.description = description
        self.price = price
        self.displayPrice = displayPrice
        self.isFamilyShareable = isFamilyShareable
        self.isPurchased = isPurchased
    }
}

public enum PurchasesError: Error {
    case unverified
    case failed(Error)
}
