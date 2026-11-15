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

/// Builds arrays from individual elements and arrays, supporting conditionals and loops.
/// Elements retain their declaration order and duplicates.
///
/// ```swift
/// let verbose = true
/// let arguments = Array {
///     "export"
///     if verbose { "--verbose" }
///     ["--output", "report.json"]
/// }
///
/// @ArrayBuilder<String>
/// var items: [String] {
///     "Home"
///     for name in ["Help", "Settings"] { name }
/// }
/// ```
///
/// Also supports `Set { ... }` and `Dictionary { (key, value) ... }` initializers.
/// Sets remove duplicates; dictionaries keep the last value for each key by default.
@resultBuilder
public enum ArrayBuilder<Element>: Sendable {
    public static func buildExpression(
        _ expression: Element
    ) -> [Element] {
        [expression]
    }
    
    public static func buildExpression(
        _ expression: [Element]
    ) -> [Element] {
        expression
    }
    
    public static func buildBlock(
        _ components: [Element]...
    ) -> [Element] {
        components.flatMap { $0 }
    }
    
    public static func buildOptional(
        _ component: [Element]?
    ) -> [Element] {
        component ?? []
    }
    
    public static func buildEither(
        first component: [Element]
    ) -> [Element] {
        component
    }
    
    public static func buildEither(
        second component: [Element]
    ) -> [Element] {
        component
    }
    
    public static func buildArray(
        _ components: [[Element]]
    ) -> [Element] {
        components.flatMap { $0 }
    }
    
    public static func buildLimitedAvailability(
        _ component: [Element]
    ) -> [Element] {
        component
    }
    
    public static func buildFinalResult(
        _ component: [Element]
    ) -> [Element] {
        component
    }
}

public extension Array {
    init(@ArrayBuilder<Element> build: () -> [Element]) {
        self = build()
    }
}

public extension Set {
    init(@ArrayBuilder<Element> build: () -> [Element]) {
        self.init(build())
    }
}

public extension Dictionary {
    /// Builds a dictionary from key-value pairs, keeping the last value for duplicate keys.
    init(@ArrayBuilder<(Key, Value)> build: () -> [(Key, Value)]) {
        self.init(build(), uniquingKeysWith: { _, new in new })
    }
}
