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

public typealias EventAskCombined<Input, Output> = EventAskEx<Input, Output, Output>
public typealias EventAsk<Input, Output> = EventAskEx<Input, Output, [Output]>

public class EventAskEx<Input, Transformed, Output> {
    public typealias AsyncTransform = (Input, @escaping (Transformed) -> Void) -> Void
    public typealias SyncTransform = (Input) -> Transformed
    
    public init(transform: @escaping ([Transformed]) -> Output) {
        _combine = transform
    }
    
    public convenience init() where Output == [Transformed] {
        self.init { $0 }
    }
    
    // MARK: Ask
    
    public func askAsync(_ value: Input, receive queue: DispatchQueue = .global(), completion: @escaping (Output) -> Void) {
        transform(value, queue: queue, completion: completion)
    }
    
    public func askSync(_ value: Input) -> Output {
        var output: Output!
        transform(value, queue: nil) { output = $0 }
        return output
    }
    
    private func transform(_ value: Input, queue: DispatchQueue?, completion: @escaping (Output) -> Void) {
        let transforms = _transforms.read { $0.values }
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
    
    // MARK: Subscribe
    
    public func subscribe(on queue: DispatchQueue = .global(), transform: @escaping AsyncTransform) -> SubscriptionToken {
        let subscription = DeinitAction {}
        let id = ObjectIdentifier(subscription)
        _transforms.writeAsync {
            $0[id] = (transform, queue)
        }
        subscription.replaceCleanup { [weak self] in self?.unsubscribe(id) }
        return subscription
    }
    
    public func subscribe(on queue: DispatchQueue = .global(), transform: @escaping SyncTransform) -> SubscriptionToken {
        subscribe(on: queue) { $1(transform($0)) }
    }
    
    private func unsubscribe(_ id: ObjectIdentifier) {
        _transforms.writeAsync {
            $0.removeValue(forKey: id)
        }
    }
    
    // MARK: Private
    
    private typealias Entry<T> = (transform: AsyncTransform, queue: DispatchQueue)
    private let _transforms = Synchronized<[ObjectIdentifier: Entry<AsyncTransform>]>(.concurrent)
    private let _combine: ([Transformed]) -> Output
}
