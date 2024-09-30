//  MIT License
//
//  Copyright (c) 2023 Alkenso (Vladimir Vashurkin)
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

public func updateSwap<T>(_ a: inout T, _ b: T) -> T {
    let copy = a
    a = b
    return copy
}

public func throwingCast<T>(name: String? = nil, _ object: Any, to: T.Type) throws -> T {
    try (object as? T).get(CommonError.cast(name: name, object, to: to))
}

public func updateValue<Value>(_ value: Value, using transform: (inout Value) -> Void) -> Value {
    var value = value
    transform(&value)
    return value
}

public func updateValue<Root, Property>(_ value: Root, at keyPath: WritableKeyPath<Root, Property>, with property: Property) -> Root {
    var value = value
    value[keyPath: keyPath] = property
    return value
}
