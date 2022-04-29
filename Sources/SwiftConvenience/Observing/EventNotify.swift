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
    private let subscriptions = Synchronized<[UUID: (T, Any?) -> Void]>(.serial)
    public var notifyQueue: DispatchQueue?
    
    public init() {}
    
    public func subscribe(receiveValue: @escaping (T, _ context: Any?) -> Void) -> SubscriptionToken {
        let id = UUID()
        subscriptions.writeAsync { $0[id] = receiveValue }
        return DeinitAction { [weak subscriptions] in subscriptions?.writeAsync { $0.removeValue(forKey: id) } }
    }
    
    public func notify(_ value: T, context: Any? = nil) {
        subscriptions.read().values.forEach { notifyOne(value, context, action: $0) }
    }
    
    private func notifyOne(_ value: T, _ context: Any?, action: @escaping (T, Any?) -> Void) {
        if let notifyQueue = notifyQueue {
            notifyQueue.async { action(value, context) }
        } else {
            action(value, context)
        }
    }
}
