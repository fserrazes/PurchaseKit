//  Created on 09.09.22
//  Copyright © 2022 Flavio Serrazes. All rights reserved.

import Foundation

/**
 * A generic object that performs all write and read operations atomically.
 * Use it to prevent data races when accessing an object.
 *
 * - Important: The closures aren't re-entrant.
 * In other words, `Atomic` instances cannot be used from within the `modify` and `withValue` closures
 *
 * Usage:
 * ```swift
 * let foo = Atomic<MyClass>
 *
 * // read values
 * foo.withValue {
 *     let current = $0.bar
 * }
 *
 * // write value
 * foo.modify {
 *     $0.bar = 2
 * }
 * ```
 *
 * Or for single-line read/writes:
 * ```swift
 * let current = foo.value.bar
 * foo.value = MyClass()
 * ```
 **/
internal final class Atomic<T> {

    private let lock: Lock
    private var _value: T

    var value: T {
        get { withValue { $0 } }
        set { modify { $0 = newValue } }
    }

    init(_ value: T) {
        self._value = value
        self.lock = Lock()
    }

    @discardableResult
    func modify<Result>(_ action: (inout T) throws -> Result) rethrows -> Result {
        return try lock.perform {
            try action(&_value)
        }
    }

    @discardableResult
    func withValue<Result>(_ action: (T) throws -> Result) rethrows -> Result {
        return try lock.perform {
            try action(_value)
        }
    }

}
