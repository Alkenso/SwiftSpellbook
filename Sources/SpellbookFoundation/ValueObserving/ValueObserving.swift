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

@preconcurrency import Combine
import Foundation

public typealias SubscriptionToken = AnyCancellable

public protocol ValueObserving<Value> {
    associatedtype Value: Sendable
    func subscribe(
        suppressInitialNotify: Bool,
        receiveValue: @escaping @Sendable (Value, _ context: Any?) -> Void
    ) -> AnyCancellable
}

extension ValueObserving {
    public func subscribe(receiveValue: @escaping @Sendable (Value, _ context: Any?) -> Void) -> SubscriptionToken {
        subscribe(suppressInitialNotify: false, receiveValue: receiveValue)
    }
    
    public func subscribe(
        suppressInitialNotify: Bool = false,
        receiveValue: @escaping @Sendable (Value) -> Void
    ) -> AnyCancellable {
        subscribe(suppressInitialNotify: suppressInitialNotify) { value, _ in receiveValue(value) }
    }
}

extension ValueObserving {
    /// Publishes value changes in order it receives the values
    /// - Warning: When using `subscribeReceiveChange`, be sure it receives the input in right order.
    /// Avoid use `receive(on:)` with concurrent queues in upstream `ValueObserving`.
    public func subscribeChange(
        receiveChange: @escaping @Sendable (Change<Value>, _ context: Any?) -> Void
    ) -> SubscriptionToken where Value: Equatable {
        let oldValue = Atomic<Value?>(wrappedValue: nil)
        return subscribe {
            if let oldValue = oldValue.exchange($0), let change = Change(old: oldValue, new: $0) {
                receiveChange(change, $1)
            }
        }
    }
    
    public func subscribeChange(
        receiveChange: @escaping @Sendable (Change<Value>) -> Void
    ) -> SubscriptionToken where Value: Equatable {
        subscribeChange { change, _ in receiveChange(change) }
    }
}

extension ValueObserving {
    public func receive(on queue: DispatchQueue) -> AnyValueObserving<Value> {
        AnyValueObserving { suppressInitialNotify, receiveValue in
            self.subscribe(suppressInitialNotify: suppressInitialNotify) { value, context in
                nonisolated(unsafe) let context = context
                queue.async { receiveValue(value, context) }
            }
        }
    }
}

public struct AnyValueObserving<T: Sendable>: ValueObserving {
    public let subscribe: (Bool, @escaping @Sendable (T, Any?) -> Void) -> SubscriptionToken
    
    public init(subscribe: @escaping (Bool, @escaping @Sendable (T, Any?) -> Void) -> SubscriptionToken) {
        self.subscribe = subscribe
    }
    
    public func subscribe(suppressInitialNotify: Bool, receiveValue: @escaping @Sendable (T, Any?) -> Void) -> SubscriptionToken {
        subscribe(suppressInitialNotify, receiveValue)
    }
}

extension ValueObserving {
    public func stream(suppressInitialNotify: Bool = false) -> AsyncStream<(Value, Any?)> {
        .init { continuation in
            let subscription = subscribe(suppressInitialNotify: suppressInitialNotify) {
                @UncheckedSendable var value = ($0, $1)
                continuation.yield(value)
            }
            continuation.onTermination = { _ in subscription.cancel() }
        }
    }
    
    public func valueStream(suppressInitialNotify: Bool = false) -> AsyncStream<Value> {
        .init { continuation in
            let subscription = subscribe(suppressInitialNotify: suppressInitialNotify) { continuation.yield($0) }
            continuation.onTermination = { _ in subscription.cancel() }
        }
    }
}

extension ValueObserving {
    public func publisher(suppressInitialNotify: Bool = false) -> AnyPublisher<(Value, Any?), Never> {
        ValueObservingPublisher(observer: self, suppressInitialNotify: suppressInitialNotify)
            .buffer(size: 1, prefetch: .byRequest, whenFull: .dropOldest)
            .eraseToAnyPublisher()
    }
    
    public func valuePublisher(suppressInitialNotify: Bool = false) -> AnyPublisher<Value, Never> {
        publisher(suppressInitialNotify: suppressInitialNotify).map(\.0).eraseToAnyPublisher()
    }
}

private struct ValueObservingPublisher<Value>: Publisher {
    typealias Output = (Value, Any?)
    typealias Failure = Never
    
    let observer: any ValueObserving<Value>
    let suppressInitialNotify: Bool
    
    func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
        let subscription = ProxySubscription()
        subscriber.receive(subscription: subscription)
        
        subscription.onCancel = { [weak subscription] in subscription?.context = nil }
        nonisolated(unsafe) let receive: (Output) -> Void = { _ = subscriber.receive($0) }
        subscription.context = observer.subscribe(suppressInitialNotify: suppressInitialNotify) { value, context in
            receive((value, context))
        }
    }
}
