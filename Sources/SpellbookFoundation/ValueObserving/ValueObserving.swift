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

public protocol ValueObserving<Value>: Sendable {
    associatedtype Value: Sendable
    
    func observe(includingCurrentValue: Bool, _ observer: ValueObserver<Value>) -> Cancellation
}

extension ValueObserving {
    public func observe(_ observer: ValueObserver<Value>) -> Cancellation {
        observe(includingCurrentValue: false, observer)
    }
    
    public func observe(
        isolation: isolated (any Actor)? = #isolation,
        includingCurrentValue: Bool = false,
        _ observer: @escaping (Value?) async -> Void
    ) -> Cancellation {
        Task { [stream = stream(includingCurrentValue: includingCurrentValue)] in
            _ = isolation
            for await change in stream {
                await observer(change)
            }
            await observer(nil)
        }.eraseToCancellation()
    }
    
    public func stream(includingCurrentValue: Bool = false) -> AsyncStream<Value> {
        let (stream, continuation) = AsyncStream<Value>.makeStream()
        
        let observer = ValueObserver<Value> { value in
            if let value {
                continuation.yield(value)
            } else {
                continuation.finish()
            }
        }
        let subscription = observe(includingCurrentValue: includingCurrentValue, observer)
        continuation.onTermination = { _ in subscription.cancel() }
        
        return stream
    }
}

public struct ValueObserver<Value: Sendable>: Sendable {
    public var name: String?
    public var observe: @Sendable (Value?) -> Void
    
    public init(name: String? = nil, observe: @escaping @Sendable (Value?) -> Void) {
        self.name = name
        self.observe = observe
    }
    
    public func notify(_ value: Value?) {
        observe(value)
    }
}

extension ValueObserver {
    public func queue(_ queue: DispatchQueue) -> Self {
        updateValue(self, at: \.observe, with: { [notify] change in queue.async { notify(change) } })
    }
}
