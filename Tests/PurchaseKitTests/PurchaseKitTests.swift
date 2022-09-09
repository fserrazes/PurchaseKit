import XCTest
@testable import PurchaseKit

final class PurchaseKitTests: XCTestCase {
    func testPurchasesIsConfiguredCorrectly() throws {
        XCTAssertFalse(Purchases.isConfigured)
        Purchases.configure(with: ["some value"])
        
        let _ = Purchases.shared
        XCTAssertTrue(Purchases.isConfigured)
    }
}
