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

import Foundation

public typealias StoreSubscription = DeinitAction

@dynamicMemberLookup
public final class Store<T: Equatable> {
    public init(initialValue: T) {
        _value = .value(value: .serial(initialValue), subscriptions: .serial([:]))
    }
    
    public var value: T {
        switch _value {
        case .value(let value, _):
            return value.read()
        case .nested(let nested, _):
            return nested.get()
        }
    }
    
    public func update1(_ value: T) {
        update { $0 = value }
    }
    
    public func update1<Property>(_ value: Property, at keyPath: WritableKeyPath<T, Property>) {
        update { $0[keyPath: keyPath] = value }
    }
    
    private func update(body: @escaping (inout T) -> Void) {
        switch _value {
        case .value(let value, let subscriptions):
            value.writeAsync {
                let oldValue = $0
                body(&$0)
                guard let change = Change.ifChanged(old: oldValue, new: $0) else { return }
                
                let subscriptionEntries = subscriptions.read(\.values)
                subscriptionEntries.forEach { entry in
                    entry.queue.async { entry.action(change) }
                }
            }
        case .nested(let nested, _):
            nested.update(body)
        }
    }
    
    public subscript<Property>(dynamicMember keyPath: KeyPath<T, Property>) -> Property {
        value[keyPath: keyPath]
    }
    
    public subscript<Property>(dynamicMember keyPath: WritableKeyPath<T, Property>) -> Property {
        get { value[keyPath: keyPath] }
        set { self.update1(newValue, at: keyPath) }
    }
    
    public func subscribe(
        queue: DispatchQueue = .global(),
        action: @escaping (Change<T>) -> Void
    ) -> StoreSubscription {
        switch _value {
        case .value(_, let subscriptions):
            let id = UUID()
            subscriptions.writeAsync { $0[id] = .init(action: action, queue: queue) }
            return DeinitAction { subscriptions.writeAsync { $0.removeValue(forKey: id) } }
        case .nested(_, let subscribe):
            return subscribe(action)
        }
    }
    
    // MARK: Private
    private let _value: Value
    
    private init(access: GetUpdate<T>, subscribe: @escaping (@escaping (Change<T>) -> Void) -> StoreSubscription) {
        _value = .nested(access: access, subscribe: subscribe)
    }
    
    private struct SubscriptionEntry {
        var action: (Change<T>) -> Void
        var queue: DispatchQueue
    }
    
    private enum Value {
        case value(value: Synchronized<T>, subscriptions: Synchronized<[UUID: SubscriptionEntry]>)
        case nested(access: GetUpdate<T>, subscribe: (@escaping (Change<T>) -> Void) -> StoreSubscription)
    }
}

extension Store {
    public func scope<U>(_ keyPath: WritableKeyPath<T, U>) -> Store<U> {
        map(
            transform: { $0[keyPath: keyPath] },
            merge: { $0[keyPath: keyPath] = $1 }
        )
    }

    public func map<U>(transform: @escaping (T) -> U, merge: @escaping (inout T, U) -> Void) -> Store<U> {
        Store<U>(
            access: GetUpdate<U>(
                get: { transform(self.value) },
                update: { localUpdate in
                    self.update { value in
                        var localValue = transform(value)
                        localUpdate(&localValue)
                        merge(&value, localValue)
                    }
                }
            ),
            subscribe: { localOnChange in
                self.subscribe { change in
                    let old = transform(change.old)
                    let new = transform(change.new)
                    if let localChange = Change.ifChanged(old: old, new: new) {
                        localOnChange(localChange)
                    }
                }
            }
        )
    }
}
