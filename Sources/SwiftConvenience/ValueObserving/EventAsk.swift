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
    private typealias Entry<T> = (transform: AsyncTransform, queue: DispatchQueue)
    private let transforms = Synchronized<[ObjectIdentifier: Entry<AsyncTransform>]>(.concurrent)
    private let combine: ([Transformed]) -> Output
    
    public typealias AsyncTransform = (Input, @escaping (Transformed) -> Void) -> Void
    public typealias SyncTransform = (Input) -> Transformed
    
    public init(combine: @escaping ([Transformed]) -> Output) {
        self.combine = combine
    }
    
    public convenience init() where Output == [Transformed] {
        self.init { $0 }
    }
    
    // MARK: Ask
    
    public func askAsync(_ value: Input, receive queue: DispatchQueue = .global(), timeout: Timeout? = nil, completion: @escaping (Output) -> Void) {
        transform(value, queue: queue, timeout: timeout, completion: completion)
    }
    
    public func askSync(_ value: Input, timeout: Timeout? = nil) -> Output {
        var output: Output!
        transform(value, queue: nil, timeout: timeout) { output = $0 }
        return output
    }
    
    private func transform(_ value: Input, queue: DispatchQueue?, timeout: Timeout?, completion: @escaping (Output) -> Void) {
        let transforms = transforms.read { $0.values }
        
        let values = Values(count: transforms.count)
        let group = DispatchGroup()
        for (idx, entry) in transforms.enumerated() {
            group.enter()
            entry.queue.async {
                entry.transform(value) { singleResult in
                    values.set(value: singleResult, at: idx)
                    group.leave()
                }
            }
        }
        
        if let queue {
            waitAsync(on: group, with: values, queue: queue, timeout: timeout, completion: completion)
        } else {
            completion(waitSync(on: group, with: values, timeout: timeout))
        }
    }
    
    @inline(__always)
    private func waitAsync(
        on group: DispatchGroup,
        with values: Values,
        queue: DispatchQueue,
        timeout: Timeout?,
        completion: @escaping (Output) -> Void
    ) {
        let once = Closure(completion).oneShot()
        
        group.notify(queue: queue) { once(values.get(fallback: nil, combine: self.combine)) }
        
        if let timeout {
            queue.asyncAfter(deadline: .now() + timeout.interval) {
                once(values.get(fallback: timeout.fallback, combine: self.combine))
            }
        }
    }
    
    @inline(__always)
    private func waitSync(on group: DispatchGroup, with values: Values, timeout: Timeout?) -> Output {
        let waitSucceeds = group.wait(interval: timeout?.interval) == .success
        return values.get(fallback: waitSucceeds ? nil : timeout?.fallback, combine: combine)
    }
    
    // MARK: Subscribe
    
    public func subscribe(on queue: DispatchQueue = .global(), transform: @escaping AsyncTransform) -> SubscriptionToken {
        let subscription = DeinitAction {}
        let id = ObjectIdentifier(subscription)
        transforms.writeAsync {
            $0[id] = (transform, queue)
        }
        subscription.replaceCleanup { [weak self] in self?.unsubscribe(id) }
        return subscription
    }
    
    public func subscribe(on queue: DispatchQueue = .global(), transform: @escaping SyncTransform) -> SubscriptionToken {
        subscribe(on: queue) { $1(transform($0)) }
    }
    
    private func unsubscribe(_ id: ObjectIdentifier) {
        transforms.writeAsync {
            $0.removeValue(forKey: id)
        }
    }
}

extension EventAskEx {
    public struct Timeout {
        public var interval: TimeInterval
        public var fallback: Fallback?
        
        public init(_ interval: TimeInterval, fallback: Fallback? = nil) {
            self.interval = interval
            self.fallback = fallback
        }
    }
    
    public enum Fallback {
        case replaceMissed(Transformed)
        case replaceOutput(Output)
    }
}

extension EventAskEx {
    private class Values {
        private var values: [Transformed?]
        private var lock = os_unfair_lock()
        
        init(count: Int) {
            values = .init(repeating: nil, count: count)
        }
        
        func set(value: Transformed, at index: Int) {
            lock.withLock {
                values[index] = value
            }
        }
        
        func get(fallback: Fallback?, combine: ([Transformed]) -> Output) -> Output {
            switch fallback {
            case .none:
                let results = lock.withLock { values.compactMap { $0 } }
                let combined = combine(results)
                return combined
            case .replaceMissed(let singleValue):
                let results = lock.withLock { values.map { $0 ?? singleValue } }
                let combined = combine(results)
                return combined
            case .replaceOutput(let wholeResult):
                return wholeResult
            }
        }
    }
}

extension DispatchGroup {
    @inline(__always)
    fileprivate func wait(interval: TimeInterval?) -> DispatchTimeoutResult {
        if let interval {
            return wait(timeout: .now() + interval)
        } else {
            wait()
            return .success
        }
    }
}
