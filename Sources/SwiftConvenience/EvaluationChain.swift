//  MIT License
//
//  Copyright (c) 2021 Alkenso (Vladimir Vashurkin)
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


public class EvaluationChain<T, R> {
    public typealias Participant = (T, @escaping (R) -> Void) -> Void
    private typealias Entry = (participant: Participant, queue: DispatchQueue)
    private let _participants = Synchronized<[ObjectIdentifier: Entry]>([:], synchronization: .concurrent)
    
    
    public init() {}
    
    public func evaluate(_ value: T, completion: @escaping ([R]) -> Void) {
        let results: Synchronized<[R]> = .init([], synchronization: .serial)
        let group = DispatchGroup()
        for entry in _participants.read(\.values) {
            group.enter()
            entry.queue.async {
                entry.participant(value) { singleResult in
                    results.writeAsync { $0.append(singleResult) }
                    group.leave()
                }
            }
        }
        group.notify(queue: .global()) {
            completion(results.read())
        }
    }
    
    public func register(on queue: DispatchQueue = .global(), participant: @escaping Participant) -> AnyObject {
        let cleanup = DeinitAction {}
        let id = ObjectIdentifier(cleanup)
        _participants.writeAsync {
            $0[id] = (participant, queue)
        }
        return DeinitAction { [weak self] in self?.unregister(id) }
    }
    
    public func unregister(_ subscription: AnyObject) {
        unregister(ObjectIdentifier(subscription))
    }
    
    private func unregister(_ id: ObjectIdentifier) {
        _participants.writeAsync {
            $0.removeValue(forKey: id)
        }
    }
}

public extension EvaluationChain {
    func register(on queue: DispatchQueue = .global(), participant: @escaping (T) -> R) -> AnyObject {
        register(on: queue) { event, nestedHandler in nestedHandler(participant(event)) }
    }
}


public typealias NotificationChain<T> = EvaluationChain<T, Void>

public extension EvaluationChain where R == Void {
    func notify(_ value: T) {
        for entry in _participants.read(\.values) {
            entry.queue.async { entry.participant(value) { _ in} }
        }
    }
}


// MARK: - Combine support

@available(macOS 10.15, iOS 13, tvOS 13.0, watchOS 6.0, *)
public extension EvaluationChain where R == Void {
    var publisher: AnyPublisher<T, Never> {
        let subject = PassthroughSubject<T, Never>()
        var proxy = NotificationChainSubject(proxy: subject.eraseToAnyPublisher())
        proxy.chainSubscription = self.register(participant: subject.send)
        return proxy.eraseToAnyPublisher()
    }
    
    private struct NotificationChainSubject: Publisher {
        typealias Output = T
        typealias Failure = Never
        
        let proxy: AnyPublisher<Output, Failure>
        var chainSubscription: AnyObject?
        
        func receive<S>(subscriber: S) where S : Subscriber, Never == S.Failure, T == S.Input {
            proxy.receive(subscriber: subscriber)
        }
    }
}
