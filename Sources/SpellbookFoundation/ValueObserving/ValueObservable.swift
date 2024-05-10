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

@propertyWrapper
public final class ValueObserved<Value> {
    private let observable: ValueObservable<Value>
    
    public init(wrappedValue: Value) {
        self.observable = .constant(wrappedValue)
    }
    
    public init(observable: ValueObservable<Value>) {
        self.observable = observable
    }
    
    public var wrappedValue: Value { observable.value }
    public var projectedValue: ValueObservable<Value> { observable }
}


@dynamicMemberLookup
public final class ValueObservable<Value>: ValueObserving {
    private let subscribeReceive: (Bool, @escaping (Value, Any?) -> Void) -> SubscriptionToken
    
    public init(
        view: ValueView<Value>,
        subscribeReceiveValue: @escaping (Bool, @escaping (Value, _ context: Any?) -> Void) -> SubscriptionToken
    ) {
        self._value = .init(view)
        self.subscribeReceive = subscribeReceiveValue
    }
    
    @ValueViewed public var value: Value
    
    public subscript<Property>(dynamicMember keyPath: KeyPath<Value, Property>) -> Property {
        value[keyPath: keyPath]
    }
    
    public func subscribe(
        suppressInitialNotify: Bool,
        receiveValue: @escaping (Value, _ context: Any?) -> Void
    ) -> SubscriptionToken {
        subscribeReceive(suppressInitialNotify, receiveValue)
    }
}

extension ValueObservable {
    public func scope<U>(_ keyPath: KeyPath<Value, U>) -> ValueObservable<U> {
        scope { $0[keyPath: keyPath] }
    }
    
    public func scope<U>(_ transform: @escaping (Value) -> U) -> ValueObservable<U> {
        ValueObservable<U>(
            view: .init { transform(self.value) },
            subscribeReceiveValue: { suppressInitialNotify, localNotify in
                self.subscribe(suppressInitialNotify: suppressInitialNotify) { globalValue, context in
                    localNotify(transform(globalValue), context)
                }
            }
        )
    }
    
    public func optional() -> ValueObservable<Value?> {
        .init(view: .init { self.value }) { suppressInitialNotify, receiveValue in
            self.subscribe(suppressInitialNotify: suppressInitialNotify) { receiveValue($0, $1) }
        }
    }
    
    public func unwrapped<U>(default defaultValue: U) -> ValueObservable<U> where Value == U? {
        .init(view: .init { self.value ?? defaultValue }) { suppressInitialNotify, receiveValue in
            self.subscribe(suppressInitialNotify: suppressInitialNotify) { receiveValue($0 ?? defaultValue, $1) }
        }
    }
}

extension ValueObservable {
    public static func constant(_ value: Value) -> ValueObservable {
        .init(view: .constant(value)) { _, _ in .init {} }
    }
}
