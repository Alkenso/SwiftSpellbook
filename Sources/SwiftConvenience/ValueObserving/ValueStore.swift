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
    private let subscriptions: EventNotify<Value>
    private var currentValueGet: [Value]
    private var currentValue: Value
    private var updateDepth = 0
    
    private var parentUpdate: ((_ context: Any?, _ body: (inout Value) -> Void) -> Void)?
    private var parentSubscription: SubscriptionToken?
    private var updateChildren = EventNotify<Value>()
    
    public init(initialValue: Value) {
        subscriptions = EventNotify(initialValue: initialValue)
        currentValue = initialValue
        currentValueGet = [initialValue]
    }
    
    public var value: Value {
        lock.withLock { currentValueGet[updateDepth > 0 ? updateDepth - 1 : 0] }
    }
    
    public func update(_ value: Value, context: Any? = nil) {
        update(context: context) { $0 = value }
    }
    
    public func update<Property>(_ keyPath: WritableKeyPath<Value, Property>, _ property: Property, context: Any? = nil) {
        update(context: context) { $0[keyPath: keyPath] = property }
    }
    
    public func update<Property, Wrapped>(
        _ keyPath: WritableKeyPath<Wrapped, Property>, _ property: Property, context: Any? = nil
    ) where Value == Wrapped? {
        update(context: context) { $0?[keyPath: keyPath] = property }
    }
    
    /// This is designated implementation of value update.
    /// Prefer to avoid use of this method.
    /// 'body' closure is invoked under internal lock. Careless use may lead to performance problems or even deadlock
    public func update(context: Any?, body: (inout Value) -> Void) {
        if let parentUpdate = parentUpdate {
            parentUpdate(context, body)
        } else {
            directUpdate(context, body: body)
        }
    }
    
    public subscript<Property>(dynamicMember keyPath: KeyPath<Value, Property>) -> Property {
        value[keyPath: keyPath]
    }
    
    public subscript<Property>(dynamicMember keyPath: WritableKeyPath<Value, Property>) -> Property {
        get { value[keyPath: keyPath] }
        set { update(keyPath, newValue) }
    }
    
    public subscript<Property, Wrapped>(
        dynamicMember keyPath: KeyPath<Wrapped, Property>
    ) -> Property? where Value == Wrapped? {
        value?[keyPath: keyPath]
    }
    
    public func subscribe(initialNotify: Bool, receiveValue: @escaping (Value, _ context: Any?) -> Void) -> SubscriptionToken {
        lock.withLock {
            subscriptions
                .subscribe(initialNotify: initialNotify, receiveValue: receiveValue)
                .capturing(self)
        }
    }
    
    private func directUpdate(_ context: Any?, body: (inout Value) -> Void) {
        lock.withLock {
            updateDepth += 1
            defer { updateDepth -= 1 }
            
            body(&currentValue)
            
            currentValueGet.append(currentValue)
            defer { currentValueGet.removeFirst() }
            
            updateChildren.notify(currentValue, context: context)
            subscriptions.notify(currentValue, context: context)
        }
    }
}

extension ValueStore {
    public func scope<U>(_ keyPath: WritableKeyPath<Value, U>) -> ValueStore<U> {
        scope(transform: { $0[keyPath: keyPath] }, merge: { $0[keyPath: keyPath] = $1 })
    }
    
    public func scope<U>(transform: @escaping (Value) -> U, merge: @escaping (inout Value, U) -> Void) -> ValueStore<U> {
        lock.withLock {
            let scoped = ValueStore<U>(initialValue: transform(value))
            
            scoped.parentUpdate = { context, localBody in
                self.update(context: context) { globalValue in
                    var localValue = transform(globalValue)
                    localBody(&localValue)
                    merge(&globalValue, localValue)
                }
            }
            
            scoped.parentSubscription = updateChildren.subscribe { [weak scoped] globalValue, context in
                scoped?.directUpdate(context) { localValue in
                    localValue = transform(globalValue)
                }
            }
            
            return scoped
        }
    }
    
    /// Converts `ValueStore<Optional<T>>` into `ValueStore<T>`, unwrapping single level of optionality.
    /// - Parameters:
    ///     - default: the value returned used by new ValueStore if parent's value is `nil`.
    ///     - mergeIntoNil: if `false`, any changes made through new `ValueStore`
    ///                     will be **ignored** if parent's value is `nil`.
    public func unwrap<Unwrapped>(default: Unwrapped, mergeIntoNil: Bool = false) -> ValueStore<Unwrapped>
    where Value == Optional<Unwrapped> {
        scope(
            transform: { $0 ?? `default` },
            merge: {
                if $0 != nil || mergeIntoNil {
                    $0 = $1
                }
            }
        )
    }
}

@available(macOS 10.15, iOS 13, tvOS 13.0, watchOS 6.0, *)
extension ValueStore: ValueObservingPublisher {
    public typealias Output = (Value, Any?)
    public typealias Failure = Never
}

extension ValueStore {
    public var asObservable: Observable<Value> {
        Observable(
            valueRef: .init { self.value },
            subscribeReceiveValue: subscribe
        )
    }
}
