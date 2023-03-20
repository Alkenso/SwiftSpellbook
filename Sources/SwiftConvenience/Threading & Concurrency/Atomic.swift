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
    public enum Synchronization {
        case unfair
        case rwlock
        case queue(SynchronizationType)
    }
    
    private let storage: Impl<Value>
    
    public init(wrappedValue: Value, _ synchronization: Synchronization = .unfair) {
        switch synchronization {
        case .unfair:
            storage = .unfair(.init(lock: os_unfair_lock(), value: wrappedValue))
        case .rwlock:
            storage = .rwlock(.init(lock: pthread_rwlock_t(), value: wrappedValue))
        case .queue(let type):
            storage = .queue(.init(wrappedValue, synchronization: type))
        }
    }
    
    public var wrappedValue: Value {
        get { storage.read() }
        set { storage.write { $0 = newValue } }
    }
    
    public var projectedValue: Atomic<Value> { self }
    
    public func exchange(_ value: Value) -> Value {
        storage.write { updateSwap(&$0, value) }
    }
    
    public func modify<R>(_ body: (inout  Value) throws -> R) rethrows -> R {
        try storage.write(body)
    }
    
    public func initialize<T>(_ initialize: @autoclosure () -> T) -> T where Value == T? {
        storage.write {
            if let value = $0 {
                return value
            } else {
                let newValue = initialize()
                $0 = newValue
                return newValue
            }
        }
    }
}

private enum Impl<Value> {
    case unfair(LockAndValue<os_unfair_lock, Value>)
    case rwlock(LockAndValue<pthread_rwlock_t, Value>)
    case queue(Synchronized<Value>)
}

private class LockAndValue<Lock, Value> {
    var lock: Lock
    var value: Value
    
    init(lock: Lock, value: Value) {
        self.lock = lock
        self.value = value
    }
}

extension Impl {
    func read() -> Value {
        switch self {
        case .unfair(let instance):
            return instance.lock.withLock { return instance.value }
        case .rwlock(let instance):
            return instance.lock.withReadLock { return instance.value }
        case .queue(let store):
            return store.read()
        }
    }
    
    func write<R>(_ writer: (inout Value) throws -> R) rethrows -> R {
        switch self {
        case .unfair(let instance):
            return try instance.lock.withLock { try writer(&instance.value) }
        case .rwlock(let instance):
            return try instance.lock.withWriteLock { try writer(&instance.value) }
        case .queue(let store):
            return try store.write(writer)
        }
    }
}
