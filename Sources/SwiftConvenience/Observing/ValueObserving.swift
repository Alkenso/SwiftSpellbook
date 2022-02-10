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
    
    func subscribe(on queue: DispatchQueue, action: @escaping (T) -> Void) -> SubscriptionToken
}

extension ValueObserving {
    public func subscribe(action: @escaping (T) -> Void) -> SubscriptionToken {
        subscribe(on: .global(), action: action)
    }
}


protocol ChangeObserving: ValueObserving where T == Change<Value> {
    associatedtype Value
    
    var value: Value { get }
}

@available(macOS 10.15, iOS 13, tvOS 13.0, watchOS 6.0, *)
extension ChangeObserving {
    public var valuePublisher: AnyPublisher<Value, Never> {
        let subject = CurrentValueSubject<Value, Never>(value)
        var proxy = NotificationChainSubject(proxy: subject.eraseToAnyPublisher())
        proxy.chainSubscription = subscribe { subject.value = $0.new }
        subject.value = value
        return proxy.eraseToAnyPublisher()
    }
    
    public var changePublisher: AnyPublisher<Change<Value>, Never> {
        let subject = PassthroughSubject<Change<Value>, Never>()
        var proxy = NotificationChainSubject(proxy: subject.eraseToAnyPublisher())
        proxy.chainSubscription = subscribe { subject.send($0) }
        return proxy.eraseToAnyPublisher()
    }
}

@available(macOS 10.15, iOS 13, tvOS 13.0, watchOS 6.0, *)
private struct NotificationChainSubject<Output>: Publisher {
    typealias Failure = Never
    
    let proxy: AnyPublisher<Output, Failure>
    var chainSubscription: Cancellable?
    
    func receive<S>(subscriber: S) where S : Subscriber, Never == S.Failure, Output == S.Input {
        proxy.receive(subscriber: subscriber)
    }
}
