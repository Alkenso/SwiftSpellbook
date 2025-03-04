//  MIT License
//
//  Copyright (c) 2024 Alkenso (Vladimir Vashurkin)
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
public final class ValueViewed<Value> {
    private var view: ValueView<Value>
    
    public init(_ view: ValueView<Value>) {
        self.view = view
    }
    
    public convenience init(wrappedValue: @autoclosure @escaping () -> Value) {
        self.init(.init(wrappedValue))
    }
    
    public var wrappedValue: Value { view.value }
    public var projectedValue: ValueView<Value> { view }
    
    public func unsafeSetView(_ view: ValueView<Value>) { self.view = view }
}

/// Wrapper that provides access to value. Useful when value is a struct that may be changed over time.
@dynamicMemberLookup
public final class ValueView<Value> {
    private var accessor: () -> Value
    
    public init(_ accessor: @escaping () -> Value) {
        self.accessor = accessor
    }
    
    public var value: Value { accessor() }
    
    public subscript<Property>(dynamicMember keyPath: KeyPath<Value, Property>) -> Property {
        value[keyPath: keyPath]
    }
    
    public func unsafeSetAccessor(_ accessor: @escaping () -> Value) { self.accessor = accessor }
}

extension ValueView {
    public static func constant(_ value: Value) -> ValueView {
        .init { value }
    }
    
    public static func weak<U: AnyObject>(_ value: U?) -> ValueView<U?> {
        .init { [weak value] in value }
    }
    
//    public subscript<U, Property>(dynamicMember keyPath: KeyPath<U, Property>) -> Property? where Value == U? {
//        wrappedValue?[keyPath: keyPath]
//    }
}
