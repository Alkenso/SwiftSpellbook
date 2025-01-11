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

public typealias SubscriptionToken = AnyCancellable

public protocol ValueObserving<Value> {
    associatedtype Value
    func subscribe(
        suppressInitialNotify: Bool,
        receiveValue: @escaping (Value, _ context: Any?) -> Void
    ) -> AnyCancellable
}

extension ValueObserving {
    public func subscribe(receiveValue: @escaping (Value, _ context: Any?) -> Void) -> SubscriptionToken {
        subscribe(suppressInitialNotify: false, receiveValue: receiveValue)
    }
    
    public func subscribe(
        suppressInitialNotify: Bool = false,
        receiveValue: @escaping (Value) -> Void
    ) -> AnyCancellable {
        subscribe(suppressInitialNotify: suppressInitialNotify) { value, _ in receiveValue(value) }
    }
}

extension ValueObserving {
    /// Publishes value changes in order it receives the values
    /// - Warning: When using `subscribeReceiveChange`, be sure it receives the input in right order.
    /// Avoid use `receive(on:)` with concurrent queues in upstream `ValueObserving`.
    public func subscribeChange(
        receiveChange: @escaping (Change<Value>, _ context: Any?) -> Void
    ) -> SubscriptionToken where Value: Equatable {
        let oldValue = Atomic<Value?>(wrappedValue: nil)
        return subscribe {
            if let oldValue = oldValue.exchange($0), let change = Change(old: oldValue, new: $0) {
                receiveChange(change, $1)
            }
        }
    }
    
    public func subscribeChange(
        receiveChange: @escaping (Change<Value>) -> Void
    ) -> SubscriptionToken where Value: Equatable {
        subscribeChange { change, _ in receiveChange(change) }
    }
}

extension ValueObserving {
    public func receive(on queue: DispatchQueue) -> AnyValueObserving<Value> {
        AnyValueObserving { suppressInitialNotify, receiveValue in
            self.subscribe(suppressInitialNotify: suppressInitialNotify) { value, context in
                queue.async { receiveValue(value, context) }
            }
        }
    }
}

extension ValueObserving {
    public var publisher: any Publisher<(Value, Any?), Never> {
        ValueObservingPublisher(observer: self)
    }
}

public struct AnyValueObserving<T>: ValueObserving {
    public let subscribe: (Bool, @escaping (T, Any?) -> Void) -> SubscriptionToken
    
    public init(subscribe: @escaping (Bool, @escaping (T, Any?) -> Void) -> SubscriptionToken) {
        self.subscribe = subscribe
    }
    
    public func subscribe(suppressInitialNotify: Bool, receiveValue: @escaping (T, Any?) -> Void) -> SubscriptionToken {
        subscribe(suppressInitialNotify, receiveValue)
    }
}

private struct ValueObservingPublisher<Value>: Publisher {
    typealias Output = (Value, Any?)
    typealias Failure = Never
    
    let observer: any ValueObserving<Value>
    
    func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
        let subscription = ProxySubscription()
        subscriber.receive(subscription: subscription)
        
        subscription.onCancel = { [weak subscription] in subscription?.context = nil }
        subscription.context = observer.subscribe { value, context in
            _ = subscriber.receive((value, context))
        }
    }
}
