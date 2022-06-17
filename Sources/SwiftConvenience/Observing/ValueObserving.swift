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

public protocol ValueObserving {
    associatedtype T
    func subscribe(receiveValue: @escaping (T, _ context: Any?) -> Void) -> SubscriptionToken
}

public struct AnyValueObserving<T>: ValueObserving {
    public init<VO: ValueObserving>(observing: VO) where VO.T == T {
        subscribe = observing.subscribe
    }
    
    public init(subscribe: @escaping (@escaping (T, Any?) -> Void) -> SubscriptionToken) {
        self.subscribe = subscribe
    }
    
    private let subscribe: (@escaping (T, Any?) -> Void) -> SubscriptionToken
    
    public func subscribe(receiveValue: @escaping (T, Any?) -> Void) -> SubscriptionToken {
        subscribe(receiveValue)
    }
}

extension ValueObserving {
    public func receive(onQueue queue: DispatchQueue) -> AnyValueObserving<T> {
        .init { receiveValue in
            self.subscribe { value, context in
                queue.async { receiveValue(value, context) }
            }
        }
    }
}

extension ValueObserving {
    public func subscribe(receiveValue: @escaping (T) -> Void) -> SubscriptionToken {
        subscribe { value, _ in receiveValue(value) }
    }
    
    /// Publishes value changes in order it receives the values
    /// - Warning: When using `subscribeReceiveChange`, be sure it receives the input in right order.
    /// Avoid use `receive(on:)` with concurrent queues in upstream `ValueObserving`.
    public func subscribeChange(receiveChange: @escaping (Change<T>, _ context: Any?) -> Void) -> SubscriptionToken where T: Equatable {
        let oldValue = Atomic<T?>(wrappedValue: nil)
        return subscribe {
            if let oldValue = oldValue.exchange($0), let change = Change(old: oldValue, new: $0) {
                receiveChange(change, $1)
            }
        }
    }
    
    public func subscribeChange(receiveChange: @escaping (Change<T>) -> Void) -> SubscriptionToken where T: Equatable {
        subscribeChange { change, _ in receiveChange(change) }
    }
}

@available(macOS 10.15, iOS 13, tvOS 13.0, watchOS 6.0, *)
public protocol ValueObservingPublisher: ValueObserving, Publisher where Failure == Never, Output == (T, Any?) {}

@available(macOS 10.15, iOS 13, tvOS 13.0, watchOS 6.0, *)
extension ValueObservingPublisher {
    public func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
        let subscription = ProxySubscription<T>()
        subscriber.receive(subscription: subscription)
        
        subscription.onCancel = { [weak subscription] in subscription?.context = nil }
        subscription.context = subscribe { value, context in
            _ = subscriber.receive((value, context))
        }
    }
}
