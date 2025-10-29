//
//  UncheckedSendable.swift
//  SwiftSpellbook
//
//  Created by Alkenso (Vladimir Vashurkin) on 28/10/2025.
//

import Foundation

@propertyWrapper
public struct UncheckedSendable<Value>: @unchecked Sendable {
    public var wrappedValue: Value
    
    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }
    
    public init(_ wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }
    
    public var projectedValue: UncheckedSendable<Value> { self }
    
    public subscript<Property>(dynamicMember keyPath: KeyPath<Value, Property>) -> UncheckedSendable<Property> {
        .init(wrappedValue[keyPath: keyPath])
    }
}
