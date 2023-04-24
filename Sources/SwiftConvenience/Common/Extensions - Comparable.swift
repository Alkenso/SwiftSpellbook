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
public struct Clamping<Value: Comparable> {
    var value: Value
    let range: ClosedRange<Value>
    
    public init(wrappedValue value: Value, _ range: ClosedRange<Value>) {
        self.value = value.clamped(to: range)
        self.range = range
    }
    
    public var wrappedValue: Value {
        get { value }
        set { value = newValue.clamped(to: range) }
    }
}

extension Comparable {
    public func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}

public enum ComparisonRelation: String, Hashable, CaseIterable {
    case lessThan = "<"
    case lessThanOrEqual = "<="
    case equal = "=="
    case greaterThanOrEqual = ">="
    case greaterThan = ">"
}

extension Comparable {
    public func compare(to rhs: Self, relation: ComparisonRelation) -> Bool {
        switch relation {
        case .equal:
            return self == rhs
        case .lessThan:
            return self < rhs
        case .lessThanOrEqual:
            return self <= rhs
        case .greaterThan:
            return self > rhs
        case .greaterThanOrEqual:
            return self >= rhs
        }
    }
}

public protocol RawComparable: Comparable {
    associatedtype RawValue
}

extension RawComparable where Self: RawRepresentable, Self.RawValue: Comparable {
    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
