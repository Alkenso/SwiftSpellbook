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

public typealias SubscriptionToken = DeinitAction

public final class EventNotify<T>: ValueObserving {
    private typealias Handler = (T, Any?) -> Void
    
    private let lock = NSRecursiveLock()
    private var subscriptions: [UUID: Handler] = [:]
    private var lastValue: T?
    
    /// Queue to be used to notify subscribers. If not set, it will be notified on caller thread.
    public var notifyQueue: DispatchQueue?
    
    /// Create EventNotify. Acts like PassthoughtSubject from Combine.
    public convenience init() {
        self.init(initialValue: nil)
    }
    
    /// Create EventNotify with initial value. Such EventNotify will notify it's subscriber immediately
    /// with that last value (initial value or last value passed to `notify` method.
    /// Acts like CurrentValueSubject from Combine.
    public init(initialValue: T?) {
        self.lastValue = initialValue
    }
    
    public func subscribe(receiveValue: @escaping (T, _ context: Any?) -> Void) -> SubscriptionToken {
        let id = UUID()
        lock.withLock {
            subscriptions[id] = receiveValue
            if let lastValue = lastValue {
                notifyOne(lastValue, nil, action: receiveValue)
            }
        }
        return DeinitAction { [weak self] in
            guard let self = self else { return }
            self.lock.withLock { _ = self.subscriptions.removeValue(forKey: id) }
        }
    }
    
    public func notify(_ value: T, context: Any? = nil) {
        let subscriptions: [Handler] = lock.withLock {
            if lastValue != nil {
                lastValue = value
            }
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
