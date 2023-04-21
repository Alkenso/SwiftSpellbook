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
public final class Observable<Value>: ValueObserving {
    private let valueRef: ValueView<Value>
    private let subscribeReceive: (Bool, @escaping (Value, Any?) -> Void) -> SubscriptionToken
    
    public init(valueRef: ValueView<Value>, subscribeReceiveValue: @escaping (Bool, @escaping (Value, _ context: Any?) -> Void) -> SubscriptionToken) {
        self.valueRef = valueRef
        subscribeReceive = subscribeReceiveValue
    }
    
    public var value: Value { valueRef.get() }
    
    public subscript<Property>(dynamicMember keyPath: KeyPath<Value, Property>) -> Property {
        value[keyPath: keyPath]
    }
    
    public func subscribe(initialNotify: Bool, receiveValue: @escaping (Value, _ context: Any?) -> Void) -> SubscriptionToken {
        subscribeReceive(initialNotify, receiveValue)
    }
}

extension Observable {
    public func scope<U>(_ keyPath: KeyPath<Value, U>) -> Observable<U> {
        scope { $0[keyPath: keyPath] }
    }
    
    public func scope<U>(_ transform: @escaping (Value) -> U) -> Observable<U> {
        Observable<U>(
            valueRef: .init { transform(self.value) },
            subscribeReceiveValue: { initialNotify, localNotify in
                self.subscribe(initialNotify: initialNotify) { globalValue, context in
                    localNotify(transform(globalValue), context)
                }
            }
        )
    }
}

extension Observable {
    public static func constant(_ value: Value) -> Observable {
        .init(valueRef: .constant(value)) { _, _ in .stub(()) }
    }
}

@available(macOS 10.15, iOS 13, tvOS 13.0, watchOS 6.0, *)
extension Observable: ValueObservingPublisher {
    public typealias Output = (Value, Any?)
    public typealias Failure = Never
}
