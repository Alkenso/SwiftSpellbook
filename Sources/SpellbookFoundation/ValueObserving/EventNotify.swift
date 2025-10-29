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

import Combine
import Foundation

public final class EventNotify<T>: ValueObserving {
    private typealias Handler = (T, Any?) -> Void
    
    private let lock = NSRecursiveLock()
    private var subscriptions: [UUID: Handler] = [:]
    private var lastValue: T?
    
    /// Queue to be used to notify subscribers. If not set, it will be notified on caller thread.
    public var notifyQueue: DispatchQueue?
    
    /// Create EventNotify.
    public convenience init() {
        self.init(initialValue: nil)
    }
    
    /// Create EventNotify with initial value. When new subscriber makes a subscription,
    /// `EventNotify` will use the `initialValue` or last value passed to `notify` method
    ///  to notify the subscriber immediately.
    public init(initialValue: T? = nil) {
        self.lastValue = initialValue
    }
    
    public var value: T? { lock.withLock { lastValue } }
    
    public func subscribe(
        suppressInitialNotify: Bool,
        receiveValue: @escaping (T, _ context: Any?) -> Void
    ) -> SubscriptionToken {
        let id = UUID()
        lock.withLock {
            subscriptions[id] = receiveValue
            if let lastValue, !suppressInitialNotify {
                notifyOne(lastValue, nil, action: receiveValue)
            }
        }
        return .init { [weak self] in
            guard let self else { return }
            self.lock.withLock { _ = self.subscriptions.removeValue(forKey: id) }
        }
    }
    
    public func notify(_ value: T, context: Any? = nil) {
        let subscriptions = lock.withLock {
            lastValue = value
            return Array(self.subscriptions.values)
        }
        subscriptions.forEach { notifyOne(value, context, action: $0) }
    }
    
    private func notifyOne(_ value: T, _ context: Any?, action: @escaping (T, Any?) -> Void) {
        if let notifyQueue = notifyQueue {
            notifyQueue.async { action(value, context) }
        } else {
            action(value, context)
        }
    }
}
