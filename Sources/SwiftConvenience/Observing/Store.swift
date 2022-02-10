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

@dynamicMemberLookup
public final class Store<Value: Equatable>: ChangeObserving {
    public init(initialValue: Value) {
        _storage = .value(value: .serial(initialValue), subscriptions: .init())
    }
    
    public var value: Value {
        switch _storage {
        case .value(let value, _):
            return value.read()
        case .nested(let nested, _):
            return nested.get()
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
        set { self.update(newValue, at: keyPath) }
    }
    
    public func subscribe(on queue: DispatchQueue, action: @escaping (Change<Value>) -> Void) -> SubscriptionToken {
        switch _storage {
        case .value(_, let subscriptions):
            return subscriptions.subscribe(on: queue, action: action)
        case .nested(_, let subscribe):
            return subscribe(action)
        }
    }
    
    // MARK: Private
    private let _storage: Storage
    
    private init(access: GetUpdate<Value>, subscribe: @escaping (@escaping (Change<Value>) -> Void) -> SubscriptionToken) {
        _storage = .nested(access: access, subscribe: subscribe)
    }
    
    private func update(body: @escaping (inout Value) -> Void) {
        switch _storage {
        case .value(let value, let subscriptions):
            value.writeAsync {
                let oldValue = $0
                body(&$0)
                guard let change = Change.ifChanged(old: oldValue, new: $0) else { return }
                subscriptions.notify(change)
            }
        case .nested(let nested, _):
            nested.update(body)
        }
    }
    
    private enum Storage {
        case value(value: Synchronized<Value>, subscriptions: SubscriptionMap<Change<Value>>)
        case nested(access: GetUpdate<Value>, subscribe: (@escaping (Change<Value>) -> Void) -> SubscriptionToken)
    }
}

extension Store {
    public func map<U>(_ keyPath: WritableKeyPath<Value, U>) -> Store<U> {
        map(transform: { $0[keyPath: keyPath] }, merge: { $0[keyPath: keyPath] = $1 })
    }

    public func map<U>(transform: @escaping (Value) -> U, merge: @escaping (inout Value, U) -> Void) -> Store<U> {
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

extension Store {
    public func asObservable() -> Observable<Value> {
        Observable(
            valueRef: .init { self.value },
            subscribe: { localNotify in
                self.subscribe { change in
                    localNotify(change)
                }
            }
        )
    }
}
