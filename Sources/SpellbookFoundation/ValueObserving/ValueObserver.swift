//  MIT License
//
//  Copyright (c) 2026 Alkenso (Vladimir Vashurkin)
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

/// Receives values and termination from a value source.
public struct ValueObserver<Value: Sendable>: Sendable {
    /// An optional diagnostic name.
    public var name: String?

    /// Handles values and source termination.
	// The closure receives `.some(value)` for a value and `nil` when the source terminates.
	/// When `Value` is optional, `.some(nil)` is still a value.
    public var observe: @Sendable (Value?) -> Void

    /// Creates an observer.
    ///
    /// - Parameters:
    ///   - name: An optional diagnostic name.
    ///   - observe: A callback receiving values and source termination.
    public init(name: String? = nil, observe: @escaping @Sendable (Value?) -> Void) {
        self.name = name
        self.observe = observe
    }
}

extension ValueObserver {
    /// Starts a pipeline with a diagnostic name.
    public static func name(_ name: String?) -> ValueObserverBuilder<Value, Value> {
        ValueObserverBuilder.identity.name(name)
    }

    /// Starts a pipeline by transforming each value.
    public static func map<Output: Sendable>(
        _ transform: @escaping @Sendable (Value) -> Output
    ) -> ValueObserverBuilder<Value, Output> {
        ValueObserverBuilder.identity.map(transform)
    }

    /// Starts a pipeline by transforming values and discarding `nil` results.
    public static func compactMap<Output: Sendable>(
        _ transform: @escaping @Sendable (Value) -> Output?
    ) -> ValueObserverBuilder<Value, Output> {
        ValueObserverBuilder.identity.compactMap(transform)
    }

    /// Starts a pipeline that forwards values matching `predicate`.
    public static func filter(
        _ predicate: @escaping @Sendable (Value) -> Bool
    ) -> ValueObserverBuilder<Value, Value> {
        ValueObserverBuilder.identity.filter(predicate)
    }

    /// Starts a pipeline that schedules downstream handling on `queue`.
    public static func queue(_ queue: DispatchQueue) -> ValueObserverBuilder<Value, Value> {
        ValueObserverBuilder.identity.queue(queue)
    }

    /// Creates an observer with synchronous callbacks.
    public static func sync(
        onTermination: (@Sendable () -> Void)? = nil,
        _ observe: @escaping @Sendable (Value) -> Void
    ) -> Self {
        ValueObserverBuilder.identity.sync(onTermination: onTermination, observe)
    }
    
    /// Creates an observer with synchronous callbacks.
    ///
    /// The caller is responsible for synchronizing captured state.
    public static func unsafeSync(
        onTermination: (() -> Void)? = nil,
        _ observe: @escaping (Value) -> Void
    ) -> Self {
        ValueObserverBuilder.identity.unsafeSync(onTermination: onTermination, observe)
    }

    /// Creates an observer with sequential asynchronous callbacks.
    public static func async(
        isolation: isolated (any Actor)? = #isolation,
        onTermination: (() async -> Void)? = nil,
        _ observe: @escaping (Value) async -> Void
    ) -> Self {
        ValueObserverBuilder.identity.async(
            isolation: isolation,
            onTermination: onTermination,
            observe
        )
    }
}

/// Builds a `ValueObserver<Input>` by composing transformations from `Input` to `Output`.
public struct ValueObserverBuilder<Input: Sendable, Output: Sendable>: Sendable {
    private typealias Downstream = @Sendable (Output?) -> Void

    private let build: @Sendable (@escaping Downstream) -> ValueObserver<Input>

    private init(build: @escaping @Sendable (@escaping Downstream) -> ValueObserver<Input>) {
        self.build = build
    }

    /// Assigns a diagnostic name to the resulting observer.
    public func name(_ name: String?) -> Self {
        Self { downstream in
            var observer = build(downstream)
            observer.name = name
            return observer
        }
    }

    /// Transforms each value.
    public func map<NewOutput: Sendable>(
        _ transform: @escaping @Sendable (Output) -> NewOutput
    ) -> ValueObserverBuilder<Input, NewOutput> {
        .init { downstream in build { downstream($0.map(transform)) } }
    }

    /// Transforms each value and discards `nil` results.
    public func compactMap<NewOutput: Sendable>(
        _ transform: @escaping @Sendable (Output) -> NewOutput?
    ) -> ValueObserverBuilder<Input, NewOutput> {
        .init { downstream in
            build { value in
                if let value {
                    transform(value).map(downstream)
                } else {
                    downstream(nil)
                }
            }
        }
    }

    /// Forwards values matching `predicate`.
    public func filter(_ predicate: @escaping @Sendable (Output) -> Bool) -> Self {
        compactMap { predicate($0) ? $0 : nil }
    }

    /// Schedules all downstream handling, including termination, on `queue`.
    public func queue(_ queue: DispatchQueue) -> Self {
        .init { downstream in
            build { value in queue.async { downstream(value) } }
        }
    }
    
    /// Builds an observer with synchronous, sendable callbacks.
    public func sync(
        onTermination: (@Sendable () -> Void)? = nil,
        _ observe: @escaping @Sendable (Output) -> Void
    ) -> ValueObserver<Input> {
        build { $0.map(observe) ?? onTermination?() }
    }
    
    /// Builds an observer without requiring sendable callbacks.
    ///
    /// The caller is responsible for synchronizing captured state.
    public func unsafeSync(
        onTermination: (() -> Void)? = nil,
        _ observe: @escaping (Output) -> Void
    ) -> ValueObserver<Input> {
        nonisolated(unsafe) let observe = observe
        nonisolated(unsafe) let onTermination = onTermination
        return build { $0.map(observe) ?? onTermination?() }
    }

    /// Builds an observer that processes values sequentially on the caller's isolation.
    public func async(
        isolation: isolated (any Actor)? = #isolation,
        onTermination: (() async -> Void)? = nil,
        _ observe: @escaping (Output) async -> Void
    ) -> ValueObserver<Input> {
        let (stream, continuation) = AsyncStream<Output?>.makeStream()
        let lifetime = Cancellation { continuation.finish() }

        Task {
            _ = isolation
            for await value in stream {
                if let value {
                    await observe(value)
                } else {
                    await onTermination?()
                }
            }
        }

        return build { value in
            _ = lifetime
            continuation.yield(value)
        }
    }
}

extension ValueObserverBuilder where Input == Output {
    fileprivate static var identity: Self {
        .init { ValueObserver(observe: $0) }
    }
}
