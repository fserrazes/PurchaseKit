//  Created on 09.09.22
//  Copyright © 2022 Flavio Serrazes. All rights reserved.

import Foundation

public protocol PurchasesProtocol {
    func requestProducts() async -> Result<[StoreProduct], PurchasesError>
    func purchase(productId: String) async throws -> Bool
    func restore() async
}
