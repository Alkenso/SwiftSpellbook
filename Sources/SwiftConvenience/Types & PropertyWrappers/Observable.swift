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

public final class Observable<T> {
    private let subscriptions = SubscriptionMap<Change<T>>()
    private let valueRef: ValueView<T>
    
    public init(valueRef: ValueView<T>) {
        self.valueRef = valueRef
    }
    
    public var value: T { valueRef.get() }
    public var userInfo: Any?
    
    public subscript<Property>(dynamicMember keyPath: KeyPath<T, Property>) -> Property {
        value[keyPath: keyPath]
    }
    
    public func subscribe(
        queue: DispatchQueue = .global(),
        action: @escaping (Change<T>) -> Void
    ) -> SubscriptionToken {
        subscriptions.subscribe(queue: queue, action: action)
    }
    
    public func notify(_ change: Change<T>) {
        subscriptions.notify(change)
    }
}

extension Observable {
    public func map<U>(_ transform: @escaping (T) -> U) -> Observable<U> {
        let mapped = Observable<U>(valueRef: .init { transform(self.value) })
        mapped.userInfo = subscribe { mapped.notify($0.map(transform)) }
        
        return mapped
    }
}
