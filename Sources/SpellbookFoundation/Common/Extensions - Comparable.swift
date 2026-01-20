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

public protocol ClampingRange<Bound>: RangeExpression & Sendable {
    func clamp(_ value: Bound) -> Bound
}

extension ClosedRange: ClampingRange {
    public func clamp(_ value: Bound) -> Bound {
        Swift.min(Swift.max(value, lowerBound), upperBound)
    }
}

extension PartialRangeFrom: ClampingRange {
    public func clamp(_ value: Bound) -> Bound {
        Swift.max(value, lowerBound)
    }
}

extension PartialRangeThrough: ClampingRange {
    public func clamp(_ value: Bound) -> Bound {
        Swift.min(value, upperBound)
    }
}

@propertyWrapper
public struct Clamped<Value: Comparable> {
    private var value: Value
    private let range: any ClampingRange<Value>
    
    public init<R: ClampingRange>(wrappedValue value: Value, _ range: R) where R.Bound == Value {
        self.value = value.clamped(to: range)
        self.range = range
    }
    
    public var wrappedValue: Value {
        get { value }
        set { value = newValue.clamped(to: range) }
    }
}

extension Clamped: Sendable where Value: Sendable {}

extension Comparable {
    public func clamped<R: ClampingRange>(to limits: R) -> Self where R.Bound == Self {
        limits.clamp(self)
    }
}

public enum ComparisonRelation: String, Hashable, CaseIterable, Sendable {
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
