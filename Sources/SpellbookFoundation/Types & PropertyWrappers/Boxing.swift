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

public struct Weak<Value: AnyObject> {
    public weak var value: Value?
    
    public init(_ value: Value?) {
        self.value = value
    }
}

public struct Unowned<Value: AnyObject> {
    public unowned var value: Value?
    
    public init(_ value: Value?) {
        self.value = value
    }
}

@dynamicMemberLookup
public final class Box<Value> {
    public var value: Value
    
    public init(_ value: Value) {
        self.value = value
    }
    
    public subscript<Property>(dynamicMember keyPath: KeyPath<Value, Property>) -> Property {
        value[keyPath: keyPath]
    }
    
    public subscript<Property>(dynamicMember keyPath: WritableKeyPath<Value, Property>) -> Property {
        get { value[keyPath: keyPath] }
        set { value[keyPath: keyPath] = newValue }
    }
}

extension Box {
    public convenience init<T>() where Value == T? {
        self.init(nil)
    }
}

extension Box: Equatable where Value: Equatable {
    public static func == (lhs: Box<Value>, rhs: Box<Value>) -> Bool {
        lhs.value == rhs.value
    }
}

extension Box: Hashable where Value: Hashable {
    public func hash(into hasher: inout Hasher) {
        value.hash(into: &hasher)
    }
}

extension Box: Identifiable where Value: Identifiable {
    public var id: Value.ID { value.id }
}

public typealias WeakBox<Value: AnyObject> = Box<Weak<Value>>

@propertyWrapper
public enum Indirect<Value> {
    indirect case wrappedValue(Value)
    
    public init(wrappedValue: Value) {
        self = .wrappedValue(wrappedValue)
    }
    
    public var wrappedValue: Value {
        get { switch self { case .wrappedValue(let value): return value } }
        set { self = .wrappedValue(newValue) }
    }
}

extension Indirect: Equatable where Value: Equatable {}
extension Indirect: Hashable where Value: Hashable {}
extension Indirect: Encodable, PropertyWrapperEncodable where Value: Encodable {}
extension Indirect: Decodable, PropertyWrapperDecodable where Value: Decodable {}

extension Indirect: Identifiable where Value: Identifiable {
    public var id: Value.ID { wrappedValue.id }
}
