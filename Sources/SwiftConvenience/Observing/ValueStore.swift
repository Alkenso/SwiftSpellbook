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
    public convenience init(initialValue: Value) {
        self.init(.storage(valueView: Atomic(wrappedValue: initialValue), valueStorage: .serial(initialValue), subscriptions: .init()))
    }
    
    public var filters: [(Value) -> Bool] = []
    
    public var value: Value {
        switch impl {
        case .storage(let valueView, _, _):
            return valueView.wrappedValue
        case .reference(let access, _):
            return access.get()
        }
    }
    
    public func subscribeReceiveValue(receiveValue: @escaping (Value) -> Void) -> SubscriptionToken {
        switch impl {
        case .storage(let valueView, _, let subscriptions):
            return subscriptions.subscribe(notifyImmediately: valueView.wrappedValue, action: receiveValue)
        case .reference(_, let subscribeReveice):
            return subscribeReveice(receiveValue)
        }
    }
    
    public func update(_ value: Value) {
        update { $0 = value }
    }
    
    public func update<Property>(_ value: Property, at keyPath: WritableKeyPath<Value, Property>) {
        update { $0[keyPath: keyPath] = value }
    }
    
    public subscript<Property>(dynamicMember keyPath: KeyPath<Value, Property>) -> Property {
        value[keyPath: keyPath]
    }
    
    public subscript<Property>(dynamicMember keyPath: WritableKeyPath<Value, Property>) -> Property {
        get { value[keyPath: keyPath] }
        set { update(newValue, at: keyPath) }
    }
    
    /// This is designated implementation of value update.
    /// Prefer to avoid use of this method.
    /// 'body' closure is invoked under internal lock. Careless use may lead to performance problems or deadlock
    public func update(body: (inout Value) -> Void) {
        switch impl {
        case .storage(let valueView, let valueStorage, let subscriptions):
            valueStorage.write { [filters] (storedValue: inout Value) in
                var newValue = storedValue
                body(&newValue)
                guard filters.isIncluded(newValue) else { return }
                storedValue = newValue
                subscriptions.notify(storedValue)
                valueView.wrappedValue = storedValue
            }
        case .reference(let access, _):
            access.update(body, filters)
        }
    }
    
    // MARK: Private
    private enum Impl {
        case storage(valueView: Atomic<Value>, valueStorage: Synchronized<Value>, subscriptions: SubscriptionMap<Value>)
        case reference(access: StoreGetUpdate<Value>, subscribeReveice: (@escaping (Value) -> Void) -> SubscriptionToken)
    }
    
    private let impl: Impl
    
    private init(_ impl: Impl) {
        self.impl = impl
    }
    
    private convenience init(access: StoreGetUpdate<Value>, subscribeReceiveValue: @escaping (@escaping (Value) -> Void) -> SubscriptionToken) {
        self.init(.reference(access: access, subscribeReveice: subscribeReceiveValue))
    }
}

private struct StoreGetUpdate<Value> {
    var get: () -> Value
    var update: ((inout Value) -> Void, [(Value) -> Bool]) -> Void
}

private typealias StoreFilter<Value> = (Value) -> Bool
private extension Array {
    func isIncluded<Value>(_ value: Value) -> Bool where Element == StoreFilter<Value> {
        for filter in self {
            guard filter(value) else { return false }
        }
        return true
    }
}

extension ValueStore {
    public func scope<U>(_ keyPath: WritableKeyPath<Value, U>) -> ValueStore<U> {
        scope(transform: { $0[keyPath: keyPath] }, merge: { $0[keyPath: keyPath] = $1 })
    }

    public func scope<U>(transform: @escaping (Value) -> U, merge: @escaping (inout Value, U) -> Void) -> ValueStore<U> {
        ValueStore<U>(
            access: StoreGetUpdate<U>(
                get: { transform(self.value) },
                update: { localUpdateBody, filters in
                    self.update { value in
                        var localValue = transform(value)
                        localUpdateBody(&localValue)
                        guard filters.isIncluded(localValue) else { return }
                        merge(&value, localValue)
                    }
                }
            ),
            subscribeReceiveValue: { localOnChange in
                self.subscribeReceiveValue { change in
                    localOnChange(transform(change))
                }
            }
        )
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
