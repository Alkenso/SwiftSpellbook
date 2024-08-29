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

private let log = SpellbookLogger.internal(category: "EventAsk")

public typealias EventAskCombined<Input, Output> = EventAskEx<Input, Output, Output>
public typealias EventAsk<Input, Output> = EventAskEx<Input, Output, [Output]>

public class EventAskEx<Input, Transformed, Output> {
    private typealias Entry<T> = (transform: AsyncTransform, queue: DispatchQueue?)
    private let transforms = Synchronized<[UUID: Entry<AsyncTransform>]>(.concurrent)
    private let combine: ([Transformed]) -> Output
    
    public typealias AsyncTransform = (Input, @escaping (Transformed) -> Void) -> Void
    public typealias SyncTransform = (Input) -> Transformed
    public typealias ConcurrentTransform = (Input) async -> Transformed
    
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
    
    public func ask(_ value: Input, timeout: Timeout? = nil) async -> Output {
        await withCheckedContinuation {
            askAsync(value, timeout: timeout, completion: $0.resume(returning:))
        }
    }
    
    private func transform(_ value: Input, queue: DispatchQueue?, timeout: Timeout?, completion: @escaping (Output) -> Void) {
        let transforms = transforms.read { $0.values }
        
        let values = Values(count: transforms.count)
        let group = DispatchGroup()
        for (idx, entry) in transforms.enumerated() {
            group.enter()
            entry.queue.async {
                let once = AtomicFlag()
                entry.transform(value) { singleResult in
                    guard !once.testAndSet() else {
                        log.error("\(Self.self) transform action called multiple times", assert: true)
                        return
                    }
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
        let once = AtomicFlag()
        
        group.notify(queue: queue) {
            guard !once.testAndSet() else { return }
            completion(values.get(fallback: nil, combine: self.combine))
        }
        
        if let timeout {
            queue.asyncAfter(delay: timeout.interval) {
                guard !once.testAndSet() else { return }
                timeout.onTimeout?()
                completion(values.get(fallback: timeout.fallback, combine: self.combine))
            }
        }
    }
    
    @inline(__always)
    private func waitSync(on group: DispatchGroup, with values: Values, timeout: Timeout?) -> Output {
        let waitSucceeds = group.wait(interval: timeout?.interval) == .success
        if !waitSucceeds {
            timeout?.onTimeout?()
        }
        return values.get(fallback: waitSucceeds ? nil : timeout?.fallback, combine: combine)
    }
    
    // MARK: Subscribe
    
    public func subscribe(
        on queue: DispatchQueue? = .global(),
        transform: @escaping AsyncTransform
    ) -> SubscriptionToken {
        let id = UUID()
        transforms.write { $0[id] = (transform, queue) }
        return .init { [weak self] in 
            self?.transforms.write { _ = $0.removeValue(forKey: id) }
        }
    }
    
    public func subscribe(
        on queue: DispatchQueue = .global(),
        transform: @escaping SyncTransform
    ) -> SubscriptionToken {
        subscribe(on: queue) { $1(transform($0)) }
    }
    
    public func subscribe(transform: @escaping ConcurrentTransform) -> SubscriptionToken {
        subscribe(on: nil) { input, reply in
            Task {
                reply(await transform(input))
            }
        }
    }
}

extension EventAskEx {
    public struct Timeout {
        public var interval: TimeInterval
        public var fallback: Fallback?
        public var onTimeout: (() -> Void)?
        
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
        private var lock = UnfairLock()
        
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
