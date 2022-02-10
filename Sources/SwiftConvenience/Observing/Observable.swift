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

@dynamicMemberLookup
public final class Observable<Value>: ChangeObserving {
    private let subscriptions = SubscriptionMap<Change<Value>>()
    private let valueRef: ValueView<Value>
    private var parentSubscription: SubscriptionToken?
    
    public init(valueRef: ValueView<Value>, subscribe: (@escaping (Change<Value>) -> Void) -> SubscriptionToken) {
        self.valueRef = valueRef
        self.parentSubscription = subscribe { [weak self] in self?.notify($0) }
    }
    
    public var value: Value { valueRef.get() }
    
    public subscript<Property>(dynamicMember keyPath: KeyPath<Value, Property>) -> Property {
        value[keyPath: keyPath]
    }
    
    public func subscribe(on queue: DispatchQueue, action: @escaping (Change<Value>) -> Void) -> SubscriptionToken {
        subscriptions.subscribe(on: queue, action: action)
    }
    
    private func notify(_ change: Change<Value>) {
        subscriptions.notify(change)
    }
}

extension Observable {
    public func map<U>(_ keyPath: KeyPath<Value, U>) -> Observable<U> {
        map { $0[keyPath: keyPath] }
    }
    
    public func map<U>(_ transform: @escaping (Value) -> U) -> Observable<U> {
        Observable<U>(
            valueRef: .init { transform(self.value) },
            subscribe: { localNotify in
                self.subscribe { change in
                    localNotify(change.map(transform))
                }
            }
        )
    }
}
