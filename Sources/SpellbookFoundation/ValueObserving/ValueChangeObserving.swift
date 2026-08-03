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

public protocol ValueChangeObserving<Value>: Sendable {
    associatedtype Value: Sendable
    
    func observe(includingCurrentValue: Bool, _ observer: ValueChangeObserver<Value>) -> Cancellation
}

extension ValueChangeObserving {
    public func observe(_ observer: ValueChangeObserver<Value>) -> Cancellation {
        observe(includingCurrentValue: false, observer)
    }
    
    public func observe(
        isolation: isolated (any Actor)? = #isolation,
        includingCurrentValue: Bool = false,
        _ observer: @escaping (ValueChange<Value>?) async -> Void
    ) -> Cancellation {
        Task { [stream = stream(includingCurrentValue: includingCurrentValue)] in
            _ = isolation
            for await change in stream {
                await observer(change)
            }
            await observer(nil)
        }.eraseToCancellation()
    }
    
    public func stream(includingCurrentValue: Bool = false) -> AsyncStream<ValueChange<Value>> {
        let (stream, continuation) = AsyncStream<ValueChange<Value>>.makeStream()
        
        let observer = ValueChangeObserver<Value> { change in
            if let change {
                continuation.yield(change)
            } else {
                continuation.finish()
            }
        }
        let subscription = observe(includingCurrentValue: includingCurrentValue, observer)
        continuation.onTermination = { _ in subscription.cancel() }
        
        return stream
    }
}

public struct ValueChange<Value: Sendable>: Sendable {
    public var old: Value
    public var new: Value
    public nonisolated(unsafe) var context: Any?
    
    public init(old: Value, new: Value, context: Any? = nil) {
        self.old = old
        self.new = new
        self.context = context
    }
    
    public func map<U>(_ transform: (Value) -> U) -> ValueChange<U> {
        .init(old: transform(old), new: transform(new), context: context)
    }
}

public struct ValueChangeContextCurrentValue: Equatable, Sendable {
    public init() {}
}

public struct ValueChangeObserver<Value: Sendable>: Sendable {
    public var name: String?
    public var notify: @Sendable (ValueChange<Value>?) -> Void
    
    public init(name: String? = nil, notify: @escaping @Sendable (ValueChange<Value>?) -> Void) {
        self.name = name
        self.notify = notify
    }
}

extension ValueChangeObserver {
    public func queue(_ queue: DispatchQueue) -> Self {
        updateValue(self, at: \.notify, with: { [notify] change in queue.async { notify(change) } })
    }
}
