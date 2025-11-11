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

import Foundation

extension DispatchQueue {
    /// Schedule some work to be executed on queue.
    /// Cancels previous execution block if it not running yet.
    public func debounce(with context: DebounceContext, execute: @escaping () -> Void) {
        context.schedule(on: self, execute: execute)
    }
}

public class DebounceContext {
    private let delay: TimeInterval
    @Atomic private var currentTask: DispatchWorkItem?
    
    public init(delay: TimeInterval) {
        self.delay = delay
    }
    
    public func schedule(on queue: DispatchQueue, execute: @escaping () -> Void) {
        let task = DispatchWorkItem(block: execute)
        let previousTask = _currentTask.exchange(task)
        previousTask?.cancel()
        queue.asyncAfter(deadline: .now() + delay, execute: task)
    }
    
    public func cancel() {
        _currentTask.exchange(nil)?.cancel()
    }
}

extension DispatchQueue {
    public func asyncAfter(
        delay: TimeInterval,
        qos: DispatchQoS = .unspecified,
        flags: DispatchWorkItemFlags = [],
        execute work: @escaping @Sendable () -> Void
    ) {
        asyncAfter(deadline: .now() + delay, qos: qos, flags: flags, execute: work)
    }
    
    public func asyncAfter(delay: TimeInterval, execute: DispatchWorkItem) {
        asyncAfter(deadline: .now() + delay, execute: execute)
    }
    
    public func asyncPeriodically(
        interval: TimeInterval,
        immediately: Bool,
        qos: DispatchQoS = .unspecified,
        flags: DispatchWorkItemFlags = [],
        execute: @escaping @Sendable () -> Bool
    ) {
        @Sendable func schedule(firstRun: Bool) {
            asyncAfter(delay: (firstRun && immediately) ? 0 : interval, qos: qos, flags: flags) {
                if execute() {
                    schedule(firstRun: false)
                }
            }
        }
        schedule(firstRun: true)
    }
    
    public func asyncPeriodically(
        interval: TimeInterval,
        immediately: Bool,
        qos: DispatchQoS = .unspecified,
        flags: DispatchWorkItemFlags = [],
        execute: @escaping @Sendable (@escaping @Sendable () -> Void) -> Void
    ) {
        @Sendable func schedule(firstRun: Bool) {
            asyncAfter(delay: (firstRun && immediately) ? 0 : interval, qos: qos, flags: flags) {
                execute {
                    schedule(firstRun: false)
                }
            }
        }
        schedule(firstRun: true)
    }
}

extension DispatchQueue {
    /// Performs `work` on the main thread.
    /// Usual `sync` method with check that the caller context is already main queue.
    public static func syncOnMain<T: Sendable>(execute work: @MainActor () throws -> T) rethrows -> T {
        if Thread.isMainThread {
            return try MainActor.assumeIsolated { try work() }
        } else {
            return try DispatchQueue.main.sync(execute: work)
        }
    }
}
