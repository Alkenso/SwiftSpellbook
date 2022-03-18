//  MIT License
//
//  Copyright (c) 2022 Alkenso (Vladimir Vashurkin)
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

import Combine
import Foundation

@dynamicMemberLookup
public final class ValueStore<Value>: ValueObserving {
    private let lock = NSRecursiveLock()
    private let subscriptions = SubscriptionMap<Value>()
    private var currentValueGet: [Value]
    private var currentValue: Value
    private var updateDepth = 0
    
    private var parentUpdate: (((inout Value) -> Void) -> Void)?
    private var parentSubscription: SubscriptionToken?
    private var updateChildren = SubscriptionMap<(Value, ObjectIdentifier)>()
    
    public init(initialValue: Value) {
        currentValue = initialValue
        currentValueGet = [initialValue]
    }
    
    public var value: Value {
        lock.withLock { currentValueGet[updateDepth > 0 ? updateDepth - 1 : 0] }
    }
    
    public func update(_ value: Value) {
        update { $0 = value }
    }
    
    public func update<Property>(_ value: Property, at keyPath: WritableKeyPath<Value, Property>) {
        update { $0[keyPath: keyPath] = value }
    }
    
    /// This is designated implementation of value update.
    /// Prefer to avoid use of this method.
    /// 'body' closure is invoked under internal lock. Careless use may lead to performance problems or deadlock
    public func update(body: (inout Value) -> Void) {
        if let parentUpdate = parentUpdate {
            parentUpdate(body)
        } else {
            directUpdate(body: body)
        }
    }
    
    public subscript<Property>(dynamicMember keyPath: KeyPath<Value, Property>) -> Property {
        value[keyPath: keyPath]
    }
    
    public subscript<Property>(dynamicMember keyPath: WritableKeyPath<Value, Property>) -> Property {
        get { value[keyPath: keyPath] }
        set { self.update(newValue, at: keyPath) }
    }
    
    public func subscribeReceiveValue(receiveValue: @escaping (Value) -> Void) -> SubscriptionToken {
        subscriptions.subscribe(notifyImmediately: value, action: receiveValue)
    }
    
    private func directUpdate(body: (inout Value) -> Void) {
        lock.withLock {
            updateDepth += 1
            defer { updateDepth -= 1 }
            
            body(&currentValue)
            
            currentValueGet.append(currentValue)
            defer { currentValueGet.removeFirst() }
            
            updateChildren.notify((currentValue, ObjectIdentifier(self)))
            subscriptions.notify(currentValue)
        }
    }
}

extension ValueStore {
    public func scope<U>(_ keyPath: WritableKeyPath<Value, U>) -> ValueStore<U> {
        scope(transform: { $0[keyPath: keyPath] }, merge: { $0[keyPath: keyPath] = $1 })
    }
    
    public func scope<U>(transform: @escaping (Value) -> U, merge: @escaping (inout Value, U) -> Void) -> ValueStore<U> {
        let scoped = ValueStore<U>(initialValue: transform(value))
        scoped.parentUpdate = { localBody in
            self.update { globalValue in
                var localValue = transform(globalValue)
                localBody(&localValue)
                merge(&globalValue, localValue)
            }
        }
        
        scoped.parentSubscription = self.updateChildren.subscribe { [weak scoped] globalValue, owner in
            scoped?.directUpdate { localValue in
                localValue = transform(globalValue)
            }
        }
        
        return scoped
    }
}

@available(macOS 10.15, iOS 13, tvOS 13.0, watchOS 6.0, *)
extension ValueStore: ValueObservingPublisher {
    public typealias Output = Value
    public typealias Failure = Never
}

extension ValueStore {
    public var asObservable: Observable<Value> {
        Observable(
            valueRef: .init { self.value },
            subscribeReceiveValue: subscribeReceiveValue
        )
    }
}