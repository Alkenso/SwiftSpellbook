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

@dynamicMemberLookup
public struct Weak<Value: AnyObject> {
    public weak var value: Value?
    
    public init(_ value: Value?) {
        self.value = value
    }
    
    public subscript<Property>(dynamicMember keyPath: KeyPath<Value, Property>) -> Property? {
        value?[keyPath: keyPath]
    }
}


@propertyWrapper
@dynamicMemberLookup
public final class Box<Value> {
    public var wrappedValue: Value
    
    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }
    
    public subscript<Property>(dynamicMember keyPath: KeyPath<Value, Property>) -> Property {
        wrappedValue[keyPath: keyPath]
    }
    
    public subscript<Property>(dynamicMember keyPath: WritableKeyPath<Value, Property>) -> Property {
        get { wrappedValue[keyPath: keyPath] }
        set { wrappedValue[keyPath: keyPath] = newValue }
    }
}

public typealias WeakBox<Value: AnyObject> = Box<Weak<Value>>

extension Box {
    public convenience init<T>(wrappedValue: T?) where Value == Weak<T> {
        self.init(wrappedValue: Weak(wrappedValue))
    }
}


@propertyWrapper
public struct GetSet<Value> {
    public var get: () -> Value
    public var set: (Value) -> Void
    
    public var wrappedValue: Value {
        get { get() }
        set { set(newValue) }
    }
    
    public init(get: @escaping () -> Value, set: @escaping (Value) -> Void) {
        self.get = get
        self.set = set
    }
}

@propertyWrapper
public struct GetUpdate<Value> {
    public var get: () -> Value
    public var update: ((inout Value) -> Void) -> Void
    
    public var wrappedValue: Value {
        get { get() }
        set { update { $0 = newValue } }
    }
    
    public init(get: @escaping () -> Value, update: @escaping ((inout Value) -> Void) -> Void) {
        self.get = get
        self.update = update
    }
}

@propertyWrapper
public struct GetEscapingUpdate<Value> {
    public var get: () -> Value
    public var update: (@escaping (inout Value) -> Void) -> Void
    
    public var wrappedValue: Value {
        get { get() }
        set { update { $0 = newValue } }
    }
    
    public init(get: @escaping () -> Value, update: @escaping (@escaping (inout Value) -> Void) -> Void) {
        self.get = get
        self.update = update
    }
}


/// Wrapper that provides access to value. Useful when value is a struct that may be changed over time.
@dynamicMemberLookup
public final class ValueView<Value> {
    private let accessor: () -> Value
    
    public init(_ accessor: @escaping () -> Value) {
        self.accessor = accessor
    }
    
    public func get() -> Value { accessor() }
    
    public subscript<Property>(dynamicMember keyPath: KeyPath<Value, Property>) -> Property {
        (get())[keyPath: keyPath]
    }
}

extension ValueView {
    public static func `weak`<U: AnyObject>(_ value: U) -> ValueView<U?> {
        .init { [weak value] in value }
    }
    
    public subscript<U, Property>(dynamicMember keyPath: KeyPath<U, Property>) -> Property? where Value == Optional<U> {
        (get())?[keyPath: keyPath]
    }
}
