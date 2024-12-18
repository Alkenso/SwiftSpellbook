//  MIT License
//
//  Copyright (c) 2021 Alkenso (Vladimir Vashurkin)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import Foundation

/// Atomic property wrapper is designed to simple & safe operations of
/// getting / setting particular value.
/// For reacher thread-safe functionality consider using 'Synchronized' class.
@propertyWrapper
public final class Atomic<Value> {
    private let storage: Synchronized<Value>
    
    public convenience init(wrappedValue: Value, _ primitive: Synchronized<Value>.Primitive = .unfair) {
        self.init(storage: .init(primitive, wrappedValue))
    }
    
    public init(storage: Synchronized<Value>) {
        self.storage = storage
    }
    
    public var wrappedValue: Value {
        get { storage.read() }
        set { storage.write { $0 = newValue } }
    }
    
    public var projectedValue: Synchronized<Value> { storage }
    
    public func exchange(_ value: Value) -> Value {
        storage.write { updateSwap(&$0, value) }
    }
}

extension Atomic where Value: AdditiveArithmetic {
    public func increment(by diff: Value) {
        storage.write { $0 += diff }
    }
}

public final class AtomicFlag {
    private let pointer: UnsafeMutablePointer<atomic_flag>
    
    public init() {
        self.pointer = .allocate(capacity: 1)
        pointer.pointee = atomic_flag()
    }
    
    deinit {
        pointer.deinitialize(count: 1)
        pointer.deallocate()
    }
    
    public func testAndSet() -> Bool {
        atomic_flag_test_and_set(pointer)
    }
    
    public func clear() {
        atomic_flag_clear(pointer)
    }
}
