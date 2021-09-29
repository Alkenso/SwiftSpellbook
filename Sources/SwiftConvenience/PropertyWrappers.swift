//  MIT License
//
//  Copyright (c) 2021 Alkenso (Vladimir Vashurkin)
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


@propertyWrapper
public final class Atomic<Value> {
    private let _value: Synchronized<Value>
    
    
    public init(wrappedValue: Value, synchronization: SynchronizationType = .serial) {
        _value = .init(wrappedValue, synchronization: synchronization)
    }
    
    public var wrappedValue: Value {
        get { _value.read { $0 } }
        set { _value.write { $0 = newValue } }
    }
    
    public func exchange(_ value: Value) -> Value {
        _value.exchange(value)
    }
}


@propertyWrapper
public struct Clamping<Value: Comparable> {
    var value: Value
    let range: ClosedRange<Value>
    
    public init(initialValue value: Value, _ range: ClosedRange<Value>) {
        self.value = value.clamped(to: range)
        self.range = range
    }
    
    public var wrappedValue: Value {
        get { value }
        set { value = newValue.clamped(to: range) }
    }
}
