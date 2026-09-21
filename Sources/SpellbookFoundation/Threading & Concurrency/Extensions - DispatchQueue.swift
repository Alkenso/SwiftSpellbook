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
    /// Same as `async(execute:)`, but accepts non-Sendable closure by transferring its ownership to the queue.
    /// It is safe because the queue executes the submitted closure exactly once.
    /// - Note: `async` name can't be used: closures passed to any `DispatchQueue.async` are inferred as `@Sendable`.
    public func asyncSending(
        qos: DispatchQoS = .unspecified,
        flags: DispatchWorkItemFlags = [],
        execute work: sending @escaping () -> Void
    ) {
        nonisolated(unsafe) let work = work
        async(qos: qos, flags: flags) { work() }
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
    public static func syncOnMain<T: Sendable, E: Error>(execute work: @MainActor () throws(E) -> T) throws(E) -> T {
        try _typedRethrow(error: E.self) {
            if Thread.isMainThread {
                return try MainActor.assumeIsolated { try work() }
            } else {
                return try DispatchQueue.main.sync(execute: work)
            }
        }
    }
}

extension DispatchQueue {
    /// Wraps `body` into closure that performs it synchronously on the queue.
    public func wrapSync<each Arg, R, E: Error>(
        _ body: @escaping @Sendable (repeat each Arg) throws(E) -> R
    ) -> @Sendable (repeat each Arg) throws(E) -> R {
        { (args: repeat each Arg) throws(E) -> R in
            try _typedRethrow(error: E.self) {
                try self.sync { try body(repeat each args) }
            }
        }
    }
    
    /// Wraps `body` into closure that performs it asynchronously on the queue.
    public func wrapAsync<each Arg: Sendable>(
        _ body: @escaping @Sendable (repeat each Arg) -> Void
    ) -> @Sendable (repeat each Arg) -> Void {
        { (args: repeat each Arg) in
            self.async { body(repeat each args) }
        }
    }
}
