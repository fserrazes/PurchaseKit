//  Created on 09.09.22
//  Copyright © 2022 Flavio Serrazes. All rights reserved.

import Foundation

/// A lock abstraction over an instance of `NSLocking`
internal final class Lock {

    private let lock: NSLocking
    init() {
        let lock = NSLock()
        lock.name = "com.serrazes.purchasekit.lock"
        self.lock = lock
        
    }
    
    @discardableResult
    func perform<T>(_ block: () throws -> T) rethrows -> T {
        self.lock.lock()
        defer { self.lock.unlock() }

        return try block()
    }
}
