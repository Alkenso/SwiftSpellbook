//
//  File.swift
//  
//
//  Created by Alkenso (Vladimir Vashurkin) on 23.09.2021.
//

import Foundation


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
