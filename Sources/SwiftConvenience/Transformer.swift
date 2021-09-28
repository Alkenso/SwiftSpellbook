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


public typealias TransformerOneToOne<Input, Output> = Transformer<Input, Output, Output>
public typealias TransformerOneToMany<Input, Output> = Transformer<Input, Output, [Output]>

public class Transformer<Input, Transformed, Output> {
    public typealias AsyncTransform = (Input, @escaping (Transformed) -> Void) -> Void
    public typealias SyncTransform = (Input) -> Transformed
    
    
    public init(combine: @escaping ([Transformed]) -> Output) {
        _combine = combine
    }
    
    public convenience init() where Output == Array<Transformed> {
        self.init { $0 }
    }
    
    
    // MARK: Transform
    
    public func async(_ value: Input, receive queue: DispatchQueue = .global(), completion: @escaping (Output) -> Void) {
        transform(value, queue: queue, completion: completion)
    }
    
    public func sync(_ value: Input) -> Output {
        var output: Output!
        transform(value, queue: nil) { output = $0 }
        return output
    }
    
    private func transform(_ value: Input, queue: DispatchQueue?, completion: @escaping (Output) -> Void) {
        let transforms = _transforms.read(\.values)
        var transformedValues: [Transformed?] = .init(repeating: nil, count: transforms.count)
        
        let group = DispatchGroup()
        for (idx, entry) in transforms.enumerated() {
            group.enter()
            entry.queue.async {
                entry.transform(value) { singleResult in
                    transformedValues[idx] = singleResult
                    group.leave()
                }
            }
        }
        
        let submitResult = { [_combine] in
            let combined = _combine(transformedValues.compactMap { $0 })
            completion(combined)
        }
        
        if let queue = queue {
            group.notify(queue: queue, execute: submitResult)
        } else {
            group.wait()
            submitResult()
        }
    }
    
    
    // MARK: Register
    
    public func register(on queue: DispatchQueue = .global(), transform: @escaping AsyncTransform) -> CancellationToken {
        let id = UUID()
        _transforms.writeAsync {
            $0[id] = (transform, queue)
        }
        let cleanup = DeinitAction { [weak self] in self?.unregister(id) }
        return .init { cleanup.cleanup() }
    }
    
    public func register(on queue: DispatchQueue = .global(), transform: @escaping SyncTransform) -> CancellationToken {
        register(on: queue) { $1(transform($0)) }
    }
    
    private func unregister(_ id: UUID) {
        _transforms.writeAsync {
            $0.removeValue(forKey: id)
        }
    }
    
    
    // MARK: Private
    private typealias Entry<T> = (transform: AsyncTransform, queue: DispatchQueue)
    private let _transforms = Synchronized<[UUID: Entry<AsyncTransform>]>([:], synchronization: .concurrent)
    private let _combine: ([Transformed]) -> Output
}


// MARK: -

public typealias Notifier<T> = Transformer<T, Void, Void>

extension Transformer where Transformed == Void, Output == Void {
    public convenience init() {
        self.init { _ in }
    }
    
    public func notify(_ value: Input) {
        async(value) { _ in }
    }
}


// MARK: Combine support

@available(macOS 10.15, iOS 13, tvOS 13.0, watchOS 6.0, *)
extension Notifier where Transformed == Void, Output == Void {
    public var publisher: AnyPublisher<Input, Never> {
        let subject = PassthroughSubject<Input, Never>()
        var proxy = NotificationChainSubject(proxy: subject.eraseToAnyPublisher())
        proxy.chainSubscription = register(on: .global(), transform: subject.send)
        return proxy.eraseToAnyPublisher()
    }
    
    private struct NotificationChainSubject: Publisher {
        typealias Output = Input
        typealias Failure = Never
        
        let proxy: AnyPublisher<Output, Failure>
        var chainSubscription: Cancellable?
        
        func receive<S>(subscriber: S) where S : Subscriber, Never == S.Failure, Input == S.Input {
            proxy.receive(subscriber: subscriber)
        }
    }
}
