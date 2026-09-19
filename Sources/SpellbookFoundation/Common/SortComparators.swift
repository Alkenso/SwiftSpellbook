//  MIT License
//
//  Copyright (c) 2026 Alkenso (Vladimir Vashurkin)
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

extension SortComparator {
    /// Creates a `KeyPathComparator` that orders values based on a property
    /// that conforms to the `Comparable` protocol.
    /// The underlying field comparison uses `ComparableComparator<Value>()`
    /// unless the keyPath points to a `String` in which case the default string
    /// comparator, `String.StandardComparator.localizedStandard`, will be used.
    /// - Parameters:
    ///   - keyPath: The key path to the field to use for the comparison.
    ///   - order: The initial order to use for comparison.
    public static func keyPath<Root, Value: Comparable>(
        _ keyPath: any KeyPath<Root, Value> & Sendable,
        order: SortOrder = .forward
    ) -> Self where Self == KeyPathComparator<Root> {
        KeyPathComparator(keyPath, order: order)
    }
    
    /// Creates a `KeyPathComparator` that orders values based on a property
    /// that conforms to the `StringProtocol` protocol.
    /// The underlying field comparison uses `StringOptionsComparator<Value>`
    /// that compares strings using the given `options`.
    /// - Parameters:
    ///   - keyPath: The key path to the field to use for the comparison.
    ///   - options: The options to use for the string comparison.
    ///   - order: The initial order to use for comparison.
    public static func keyPath<Root, Value: StringProtocol>(
        _ keyPath: any KeyPath<Root, Value> & Sendable,
        options: String.CompareOptions,
        order: SortOrder = .forward
    ) -> Self where Self == KeyPathComparator<Root> {
        KeyPathComparator(keyPath, comparator: StringOptionsComparator(options: options), order: order)
    }
    
    /// Comparator that compares elements by string value at given `keyPath` using `options`.
    public static func string<Root: StringProtocol>(
        options: String.CompareOptions,
        order: SortOrder = .forward
    ) -> Self where Self == StringOptionsComparator<Root> {
        StringOptionsComparator(options: options, order: order)
    }
}

/// Comparator that compares strings using `String.CompareOptions`.
public struct StringOptionsComparator<Compared: StringProtocol>: SortComparator {
    public var options: String.CompareOptions
    public var order: SortOrder
    
    public init(options: String.CompareOptions, order: SortOrder = .forward) {
        self.options = options
        self.order = order
    }
    
    public func compare(_ lhs: Compared, _ rhs: Compared) -> ComparisonResult {
        order == .forward ? lhs.compare(rhs, options: options) : rhs.compare(lhs, options: options)
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(options.rawValue)
        hasher.combine(order)
    }
}
