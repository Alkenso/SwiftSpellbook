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
public final class ValueStore<Value: Sendable>: ValueObserving {
    private let valueStore: Synchronized<Value>
    private let trait: Trait
    private let downstream: Downstream
    
    public convenience init(initialValue: Value) {
        self.init(initialValue: initialValue, trait: .parent(UnfairLock()))
    }
    
    private init(initialValue: Value, trait: Trait) {
        let valueStore = Synchronized(.unfair, initialValue)
        self.valueStore = valueStore
        self.trait = trait
        self.downstream = Downstream(valueStore: valueStore)
    }
    
    deinit {
        if case .parent = trait {
            downstream.finish()
        }
    }
    
    // MARK: - Access & Observe
    
    public var value: Value { valueStore.read() }
    
    public func observe(includingCurrentValue: Bool, _ observer: ValueObserver<ValueChange<Value>>) -> Cancellation {
        downstream.register(observer: observer, withCurrentValue: includingCurrentValue)
    }
    
    public var observable: ValueObservable<Value> {
        ValueObservable(view: view, observe: observe)
    }
    
    public var view: ValueView<Value> {
        ValueView { [valueStore] in valueStore.read() }
    }
    
    // MARK: - Modify
    
    public func update<R>(context: Any? = nil, body: (inout Value) -> sending R) -> sending R {
        let result = directUpdate(context: context, body: body)
        guard let result = result as? R else {
            fatalError("Internal inconsistency: failed to cast \(result) to expected type \(R.self)")
        }
        return result
    }
    
    @discardableResult
    public func update(_ value: Value, context: Any? = nil) -> Value {
        update(context: context) { exchange(&$0, with: value) }
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
    
    public subscript<Property>(dynamicMember keyPath: KeyPath<Value, Property>) -> Property {
        value[keyPath: keyPath]
    }
    
    public subscript<Property, Wrapped>(
        dynamicMember keyPath: KeyPath<Wrapped, Property>
    ) -> Property? where Value == Wrapped? {
        value?[keyPath: keyPath]
    }
    
    public func scope<U>(transform: @escaping @Sendable (Value) -> U, merge: @escaping @Sendable (U, inout Value) -> Void) -> ValueStore<U> {
        let child = ValueStore<U>(initialValue: transform(value), trait: .child({ context, diff in
            self.directUpdate(context: context) { global in
                var local = transform(global)
                let result = diff(&local)
                merge(local, &global)
                return result
            }
        }))
        
        downstream.register(child: child.downstream, transform: transform)
        child.valueStore.write(transform(value))
        
        return child
    }
    
    private func directUpdate(context: Any?, body: (inout Value) -> sending Any) -> sending Any {
        switch trait {
        case .parent(let lock): lock.withLock { rootUpdate(context: context, body: body) }
        case .child(let parentUpdate): parentUpdate(context, body)
        }
    }
    
    private func rootUpdate(context: Any?, body: (inout Value) -> sending Any) -> sending Any {
        let oldValue = valueStore.read()
        var change = Change(old: oldValue, new: oldValue, context: context)
        let result = body(&change.new)
        downstream.yield(change)
        return result
    }
}

extension ValueStore {
    public func scope<U: Sendable>(_ keyPath: WritableKeyPath<Value, U> & Sendable) -> ValueStore<U> {
        scope(transform: { $0[keyPath: keyPath] }, merge: { $1[keyPath: keyPath] = $0 })
    }
    
    /// Converts `ValueStore<T?>` into `ValueStore<T>`, unwrapping single level of optionality.
    /// - Parameters:
    ///     - default: the value used by the new ValueStore if parent's value is `nil`.
    ///     - mergeIntoNil: if `false`, any changes made through the new `ValueStore`
    ///                     will be **ignored** if parent's value is `nil`.
    public func unwrapped<Unwrapped: Sendable>(
        default: Unwrapped, mergeIntoNil: Bool = false
    ) -> ValueStore<Unwrapped> where Value == Unwrapped? {
        scope(
            transform: { $0 ?? `default` },
            merge: { newValue, storedValue in
                if storedValue != nil || mergeIntoNil {
                    storedValue = newValue
                }
            }
        )
    }
    
    /// Converts `ValueStore<T>` into `ValueStore<T?>`, wrapping single level of optionality.
    /// - Parameters:
    ///     - fallback: used in case the optional ValueStore's value is updated to `nil`.
    ///     In such case, if `fallback` is not `nil`, it will update the original store with `fallback` value.
    public func optional(fallback: Value?) -> ValueStore<Value?> {
        scope(
            transform: { $0 },
            merge: { newValue, storedValue in
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
    private typealias Change = ValueChange<Value>
    private typealias Observer = ValueObserver<Change>
    
    private enum Trait {
        case parent(UnfairLock)
        case child(@Sendable (Any?, (_ value: inout Value) -> sending Any) -> sending Any)
    }
    
    private class Downstream: @unchecked Sendable {
        private let lock = UnfairLock()
        weak let valueStore: Synchronized<Value>?
        var observers: [UUID: Observer] = [:]
        var children: [UUID: @Sendable (Change?) -> Bool] = [:]
        
        init(valueStore: Synchronized<Value>?) {
            self.valueStore = valueStore
        }
        
        func register<U>(child: ValueStore<U>.Downstream, transform: @escaping @Sendable (Value) -> U) {
            lock.withLock { children[UUID()] = { child.notify($0?.map(transform)) } }
        }
        
        func register(observer: Observer, withCurrentValue: Bool) -> Cancellation {
            lock.withLock {
                let id = UUID()
                let cancellation = Cancellation { [self] in
                    lock.withLock { _ = observers.removeValue(forKey: id) }
                }
                observers[id] = observer
                if withCurrentValue, let value = valueStore?.read() {
                    observer.notify(Change(old: value, new: value, context: ValueChangeContextCurrentValue()))
                }
                return cancellation
            }
        }
        
        private func notify(_ change: Change?) -> Bool {
            guard let change else {
                let (observers, children) = lock.withLock { (self.observers, self.children) }
                observers.values.forEach { $0.notify(nil) }
                children.values.forEach { _ = $0(nil) }
                return false
            }
            
            let (observers, children, storeExists) = lock.withLock {
                (self.observers, self.children, valueStore?.write(change.new) != nil)
            }
            
            observers.values.forEach { $0.notify(change) }
            var childrenExist = false
            for (childID, childUpdate) in children {
                if childUpdate(change) {
                    childrenExist = true
                } else {
                    lock.withLock { _ = self.children.removeValue(forKey: childID) }
                }
            }
            
            return storeExists || !observers.isEmpty || childrenExist
        }
        
        func yield(_ change: Change) {
            _ = notify(change)
        }
        
        func finish() {
            _ = notify(nil)
        }
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
