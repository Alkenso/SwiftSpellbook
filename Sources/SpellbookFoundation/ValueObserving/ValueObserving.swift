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

public protocol ValueObserving<ObservedValue>: Sendable {
    associatedtype ObservedValue: Sendable
    
    func observe(options: ValueObservingOptions, _ observer: ValueObserver<ObservedValue>) -> Cancellation
}

/// Options that control how observation is performed.
public struct ValueObservingOptions: Hashable, Sendable, OptionSet {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }

    /// Requests immediate delivery of the current value when observation starts,
    /// if a current value is available.
    ///
    /// Some observables may not have a current value by design. In that case,
    /// enabling this option has no effect.
    public static let currentValue = Self(rawValue: 1 << 0)
}

extension ValueObserving {
    public func observe(_ observer: ValueObserver<ObservedValue>) -> Cancellation {
        observe(options: [], observer)
    }
    
    public func observe(
        isolation: isolated (any Actor)? = #isolation,
        options: ValueObservingOptions = [],
        _ observer: @escaping (ObservedValue?) async -> Void
    ) -> Cancellation {
        Task { [stream = stream(options: options)] in
            _ = isolation
            for await change in stream {
                await observer(change)
            }
            await observer(nil)
        }.eraseToCancellation()
    }
    
    public func stream(options: ValueObservingOptions = []) -> AsyncStream<ObservedValue> {
        let (stream, continuation) = AsyncStream<ObservedValue>.makeStream()
        
        let observer = ValueObserver<ObservedValue> { value in
            if let value {
                continuation.yield(value)
            } else {
                continuation.finish()
            }
        }
        let subscription = observe(options: options, observer)
        continuation.onTermination = { _ in subscription.cancel() }
        
        return stream
    }
}
