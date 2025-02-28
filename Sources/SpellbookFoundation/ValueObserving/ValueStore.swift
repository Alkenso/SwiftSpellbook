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

@propertyWrapper
public final class ValueStored<Value> {
    private let store: ValueStore<Value>
    
    public init(wrappedValue: Value) {
        self.store = .init(initialValue: wrappedValue)
    }
    
    public init(store: ValueStore<Value>) {
        self.store = store
    }
    
    public var wrappedValue: Value { store.value }
    public var projectedValue: ValueStore<Value> { store }
}

@dynamicMemberLookup
public final class ValueStore<Value>: ValueObserving {
    private let lock = NSRecursiveLock()
    private let valueLock = UnfairLock()
    private let subscriptions: EventNotify<Value>
    private var currentValueGet: [Value]
    private var currentValue: Value
    private var updateDepth = 0
    
    private var parentUpdate: ((_ context: Any?, _ body: (inout Value) -> Any) -> Any)?
    private var parentSubscription: SubscriptionToken?
    private var updateChildren = EventNotify<Value>()
    
    public init(initialValue: Value) {
        subscriptions = EventNotify(initialValue: initialValue)
        currentValue = initialValue
        currentValueGet = [initialValue]
    }
    
    public var value: Value {
        valueLock.withLock { currentValueGet[updateDepth > 0 ? updateDepth - 1 : 0] }
    }
    
    @discardableResult
    public func update(_ value: Value, context: Any? = nil) -> Value {
        update(context: context) { updateSwap(&$0, value) }
    }
    
    public func update<Property>(
        _ keyPath: WritableKeyPath<Value, Property>,
        _ property: Property,
        context: Any? = nil
    ) {
        update(context: context) { $0[keyPath: keyPath] = property }
    }
    
    public func update<Property, Wrapped>(
        _ keyPath: WritableKeyPath<Wrapped, Property>,
        _ property: Property,
        context: Any? = nil
    ) where Value == Wrapped? {
        update(context: context) { $0?[keyPath: keyPath] = property }
    }
    
    /// This is designated implementation of value update.
    /// Use it carefully: `body` closure is invoked under internal lock.
    /// Careless use may lead to performance problems or even deadlock.
    public func update<R>(context: Any? = nil, body: (inout Value) -> R) -> R {
        let result = updateImpl(context: context, body: body)
        guard let result = result as? R else {
            fatalError("Internal inconsistency: failed to cast \(result) to expected type \(R.self)")
        }
        return result
    }
    
    public subscript<Property>(dynamicMember keyPath: KeyPath<Value, Property>) -> Property {
        value[keyPath: keyPath]
    }
    
    public subscript<Property, Wrapped>(
        dynamicMember keyPath: KeyPath<Wrapped, Property>
    ) -> Property? where Value == Wrapped? {
        value?[keyPath: keyPath]
    }
    
    public func subscribe(
        suppressInitialNotify: Bool,
        receiveValue: @escaping (Value, _ context: Any?) -> Void
    ) -> SubscriptionToken {
        lock.withLock {
            subscriptions
                .subscribe(suppressInitialNotify: suppressInitialNotify, receiveValue: receiveValue)
                .capturing(self)
        }
    }
    
    private func updateImpl(context: Any?, body: (inout Value) -> Any) -> Any {
        if let parentUpdate = parentUpdate {
            parentUpdate(context, body)
        } else {
            directUpdate(context, body: body)
        }
    }
    
    private func directUpdate(_ context: Any?, body: (inout Value) -> Any) -> Any {
        lock.withLock {
            let result = body(&currentValue)
            
            valueLock.withLock {
                updateDepth += 1
                currentValueGet.append(currentValue)
            }
            
            updateChildren.notify(currentValue, context: context)
            subscriptions.notify(currentValue, context: context)
            
            valueLock.withLock {
                currentValueGet.removeFirst()
                updateDepth -= 1
            }
            
            return result
        }
    }
}

extension ValueStore {
    public func scope<U>(_ keyPath: WritableKeyPath<Value, U>) -> ValueStore<U> {
        scope(transform: { $0[keyPath: keyPath] }, merge: { $0[keyPath: keyPath] = $1 })
    }
    
    public func scope<U>(
        transform: @escaping (Value) -> U,
        merge: @escaping (inout Value, U) -> Void
    ) -> ValueStore<U> {
        lock.withLock {
            let scoped = ValueStore<U>(initialValue: transform(value))
            
            scoped.parentUpdate = { context, localBody in
                self.updateImpl(context: context) { globalValue in
                    var localValue = transform(globalValue)
                    let result = localBody(&localValue)
                    merge(&globalValue, localValue)
                    return result
                }
            }
            
            scoped.parentSubscription = updateChildren.subscribe { [weak scoped] globalValue, context in
                _ = scoped?.directUpdate(context) { localValue in
                    localValue = transform(globalValue)
                }
            }
            
            return scoped
        }
    }
    
    /// Converts `ValueStore<T?>` into `ValueStore<T>`, unwrapping single level of optionality.
    /// - Parameters:
    ///     - default: the value returned used by new ValueStore if parent's value is `nil`.
    ///     - mergeIntoNil: if `false`, any changes made through new `ValueStore`
    ///                     will be **ignored** if parent's value is `nil`.
    public func unwrapped<Unwrapped>(
        default: Unwrapped, mergeIntoNil: Bool = false
    ) -> ValueStore<Unwrapped> where Value == Unwrapped? {
        scope(
            transform: { $0 ?? `default` },
            merge: { storedValue, newValue in
                if storedValue != nil || mergeIntoNil {
                    storedValue = newValue
                }
            }
        )
    }
    
    /// Converts `ValueStore<T>` into `ValueStore<T?>`, wrapping single level of optionality.
    /// - Parameters:
    ///     - fallback: used in case optional ValueStore's value is updated to `nil`.
    ///     In such case, if `fallback` is not `nil`, it will update original store with `fallback` value.
    public func optional(fallback: Value?, mergeIntoNil: Bool = false) -> ValueStore<Value?> {
        scope(
            transform: { $0 },
            merge: { storedValue, newValue in
                if let newValue {
                    storedValue = newValue
                } else if let fallback {
                    storedValue = fallback
                }
            }
        )
    }
}

extension ValueStore {
    public var observable: ValueObservable<Value> {
        ValueObservable(
            view: .init { self.value },
            subscribeReceiveValue: subscribe
        )
    }
    
    public var view: ValueView<Value> {
        .init { self.value }
    }
}

extension ValueStore {
    public class ObservableObject: Foundation.ObservableObject {
        private var cancellables: Set<AnyCancellable> = []
        
        public init(store: ValueStore<Value>) {
            self.store = store
            self.value = store.value
            let token = UUID()
            store.subscribe { [weak self] in if ($1 as? UUID) != token { self?.value = $0 } }.store(in: &cancellables)
            $value.dropFirst().sink { store.update($0, context: token) }.store(in: &cancellables)
        }
        
        @Published public var value: Value
        public let store: ValueStore<Value>
    }
    
    public var observableObject: ValueStore.ObservableObject {
        .init(store: self)
    }
}

extension ValueStore {
    public convenience init() where Value: ExpressibleByArrayLiteral {
        self.init(initialValue: [])
    }
    
    public convenience init<Element: Hashable>() where Value == Set<Element> {
        self.init(initialValue: [])
    }
    
    public convenience init() where Value: ExpressibleByDictionaryLiteral {
        self.init(initialValue: [:])
    }
}

extension ValueStore: _ValueUpdateWrapping {
    public func _readValue<R>(body: (Value) -> R) -> R {
        update { body($0) }
    }
    
    public func _updateValue<R>(body: (inout Value) -> R) -> R {
        update(body: body)
    }
}
