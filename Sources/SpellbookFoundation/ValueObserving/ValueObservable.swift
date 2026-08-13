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
public final class ValueObservable<Value: Sendable>: ValueObserving {
    private let observe: @Sendable (Bool, ValueObserver<ValueChange<Value>>) -> Cancellation
    
    public init(
        view: ValueView<Value>,
        observe: @escaping @Sendable (Bool, ValueObserver<ValueChange<Value>>) -> Cancellation
    ) {
        self.view = view
        self.observe = observe
    }
    
    public var value: Value { view.value }
    
    public let view: ValueView<Value>
    
    public subscript<Property>(dynamicMember keyPath: KeyPath<Value, Property>) -> Property {
        value[keyPath: keyPath]
    }
    
    public func observe(includingCurrentValue: Bool, _ observer: ValueObserver<ValueChange<Value>>) -> Cancellation {
        observe(includingCurrentValue, observer)
    }
}

extension ValueObservable {
    public func scope<U: Sendable>(_ keyPath: KeyPath<Value, U> & Sendable) -> ValueObservable<U> {
        scope { $0[keyPath: keyPath] }
    }
    
    public func scope<U: Sendable>(_ transform: @escaping @Sendable (Value) -> U) -> ValueObservable<U> {
        ValueObservable<U>(
            view: .init { transform(self.value) },
            observe: { includingCurrentValue, observer in
                self.observe(
                    includingCurrentValue: includingCurrentValue,
                    ValueObserver(
                        name: observer.name.flatMap { "\($0).scope(\(U.self))" },
                        observe: { observer.notify($0?.map(transform)) }
                    )
                )
            }
        )
    }
    
    public func optional() -> ValueObservable<Value?> {
        scope(\.self)
    }
    
    public func unwrapped<U>(default defaultValue: U) -> ValueObservable<U> where Value == U? {
        scope { $0 ?? defaultValue }
    }
}

extension ValueObservable {
    public static func constant(_ value: Value) -> ValueObservable {
        .init(view: .constant(value)) { includeCurrentValue, observer in
            if includeCurrentValue {
                observer.notify(.init(old: value, new: value, context: ValueChangeContextCurrentValue()))
            }
            return .init {}
        }
    }
}
