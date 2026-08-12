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

public final class ValueBroadcast<Value: Sendable>: Sendable {
    private let observers = Synchronized<[UUID: ValueObserver<Value>]>(.unfair)
    
    public init() {}
    
    /// Queue to be used to notify observers. If not set, when will be notified on the caller thread.
    nonisolated(unsafe)
    public var notifyQueue: DispatchQueue?
    
    public func observe(_ observer: ValueObserver<Value>) -> Cancellation {
        let id = UUID()
        observers[id] = observer
        return .init { [weak observers] in observers?.removeValue(forKey: id) }
    }
    
    public func notify(_ value: Value) {
        notifyQueue.async {
            let observers = self.observers.read()
            observers.values.forEach { $0.notify(value) }
        }
    }
}
