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

@available(macOS 10.15, iOS 13, tvOS 13.0, watchOS 6.0, *)
public struct ProxyPublisher<P: Publisher>: Publisher {
    public typealias Output = P.Output
    public typealias Failure = P.Failure
    
    public let proxy: P
    public var context: Any?
    
    public init(_ publisher: P) {
        proxy = publisher
    }
    
    public func receive<S>(subscriber: S) where S: Subscriber, P.Failure == S.Failure, P.Output == S.Input {
        proxy.receive(subscriber: subscriber)
    }
}

@available(macOS 10.15, iOS 13, tvOS 13.0, watchOS 6.0, *)
public final class ProxySubscriber<S: Subscriber>: Subscriber {
    public typealias Input = S.Input
    public typealias Failure = S.Failure
    
    public let proxy: S
    public var context: Any?
    
    public init(_ subscriber: S) {
        proxy = subscriber
    }
    
    public func receive(subscription: Subscription) {
        proxy.receive(subscription: subscription)
    }
    
    public func receive(_ input: S.Input) -> Subscribers.Demand {
        proxy.receive(input)
    }
    
    public func receive(completion: Subscribers.Completion<S.Failure>) {
        proxy.receive(completion: completion)
    }
}

@available(macOS 10.15, iOS 13, tvOS 13.0, watchOS 6.0, *)
public final class ProxySubscription<Input>: Subscription {
    public var context: Any?
    
    public var onDemand: ((Subscribers.Demand) -> Void)?
    public var onCancel: (() -> Void)?
    
    public init() {}
    
    public func request(_ demand: Subscribers.Demand) {
        onDemand?(demand)
    }
    
    public func cancel() {
        onCancel?()
    }
}
