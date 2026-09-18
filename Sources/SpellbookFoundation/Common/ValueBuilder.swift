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

struct ValueBuilder<T> {
    public var value: T
    
    public func set<Property>(_ keyPath: WritableKeyPath<T, Property>, _ value: Property?) -> Self {
        guard let value = value else { return self }
        var copy = self
        copy.value[keyPath: keyPath] = value
        return copy
    }
    
    public func `if`(
        _ condition: Bool,
        then: (inout T) -> Void,
        `else`: (inout T) -> Void = { _ in }
    ) -> Self {
        var copy = self
        if condition {
            then(&copy.value)
        } else {
            `else`(&copy.value)
        }
        return copy
    }
    
    public func ifLet<U>(
        _ value: U?,
        then: (inout T, U) -> Void,
        `else`: (inout T) -> Void = { _ in }
    ) -> Self {
        var copy = self
        if let value {
            then(&copy.value, value)
        } else {
            `else`(&copy.value)
        }
        return copy
    }
    
    public func modify(_ body: (inout T) -> Void) -> Self {
        var copy = self
        body(&copy.value)
        return copy
    }
}
