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

// MARK: - SBPredicate

public struct SBPredicate<Value, Failure: Error> {
    public var evaluate: (Value) throws(Failure) -> Bool
    
    public init(_ evaluate: @escaping (Value) throws(Failure) -> Bool) {
        self.evaluate = evaluate
    }
    
    public static func `where`(_ predicate: @escaping (Value) throws(Failure) -> Bool) -> Self {
        .init(predicate)
    }
    
    public var negated: Self {
        .init { (value) throws(Failure) -> Bool in try evaluate(value) }
    }
}

extension SBPredicate where Failure == Never {
    public static func equals(to value: Value) -> Self where Value: Equatable {
        .init { $0 == value }
    }
    
    public static func equals<Property: Equatable>(
        at keyPath: KeyPath<Value, Property>,
        to value: Property
    ) -> Self {
        .init { $0[keyPath: keyPath] == value }
    }
}

// MARK: - Dictionary

extension Dictionary {
    public var reader: DictionaryReader<Key, Value> { .init(self) }
    
    /// Get the value in nested dictionary
    /// Specific cases:
    ///     - Nested Array:
    ///         - pass [1] to follow the 1-st item in the nested array
    ///         - pass [Int.max] to follow the last item in the nested array
    public subscript<R>(codingPath codingPath: [DictionaryCodingKey], as as: R.Type = R.self) -> R? {
        try? reader.read(codingPath: codingPath, as: R.self)
    }
    
    /// Get value in nested dictionary using dot-separated key path.
    /// Keys in dictionary at keyPath componenets must be of String type
    /// Specific cases:
    ///     - Nested Array:
    ///         - pass [1] to follow the 1-st item in the nested array
    ///         - pass [*] to follow the last item in the nested array
    public subscript<R>(dotPath dotPath: String, as as: R.Type = R.self) -> R? {
        try? reader.read(dotPath: dotPath, as: R.self)
    }
}

extension Dictionary {
    public var writer: DictionaryWriter<Key, Value> { .init(self) }
    
    /// Inserts value in nested dictionary using CodingPath-separated key path
    public mutating func insert(value: Any, codingPath: [DictionaryCodingKey]) -> Bool {
        var writer = DictionaryWriter(self)
        let inserted = (try? writer.insert(value: value, codingPath: codingPath)) != nil
        if inserted {
            self = writer.dictionary
        }
        return inserted
    }
    
    /// Inserts value in nested dictionary using dot-separated key path
    public mutating func insert(value: Any, dotPath: String) -> Bool {
        var writer = DictionaryWriter(self)
        let inserted = (try? writer.insert(value: value, dotPath: dotPath)) != nil
        if inserted {
            self = writer.dictionary
        }
        return inserted
    }
}

extension Dictionary {
    /// Removes the all elements from the array and returns them.
    public mutating func popAll(keepingCapacity: Bool = false) -> Self {
        guard !isEmpty else { return [:] }
        let removed = self
        removeAll(keepingCapacity: keepingCapacity)
        return removed
    }
    
    /// Removes the all elements from the array and returns them.
    public mutating func popAll(_ predicate: SBPredicate<Element, Never>) -> Self {
        guard !isEmpty else { return [:] }
        var removed: [Key: Value] = [:]
        for element in self {
            if predicate.evaluate(element) {
                removeValue(forKey: element.key)
                removed[element.key] = element.value
            }
        }
        return removed
    }
    
    /// Removes the all elements from the array and returns them.
    public mutating func popAll(where predicate: (Element) -> Bool) -> Self {
        _withoutActuallyEscaping(predicate) { popAll($0) }
    }
}

extension Dictionary {
    /// Returns a new dictionary containing the key-value pairs of the dictionary
    /// that satisfy the given predicate.
    /// Collects unsatisfied elements into `remaining` dictionary.
    ///
    /// - Parameter isIncluded: A predicate that takes a key-value pair as its
    ///   argument and returns a Boolean value indicating whether the pair
    ///   should be included in the returned dictionary.
    /// - Parameter remaining: A dictionary to collect elements that are
    ///   not included into returned dictionary.
    /// - Returns: A dictionary of the key-value pairs that `isIncluded` allows.
    public func filter<Failure>(
        remaining: inout [Key: Value],
        _ isIncluded: SBPredicate<Element, Failure>
    ) throws(Failure) -> [Key: Value] {
        var filtered: [Key: Value] = [:]
        for (key, value) in self {
            if try isIncluded.evaluate((key, value)) {
                filtered[key] = value
            } else {
                remaining[key] = value
            }
        }
        return filtered
    }
    
    /// Returns a new dictionary containing the key-value pairs of the dictionary
    /// that satisfy the given predicate.
    /// Collects unsatisfied elements into `remaining` dictionary.
    ///
    /// - Parameter isIncluded: A closure that takes a key-value pair as its
    ///   argument and returns a Boolean value indicating whether the pair
    ///   should be included in the returned dictionary.
    /// - Parameter remaining: A dictionary to collect elements that are
    ///   not included into returned dictionary.
    /// - Returns: A dictionary of the key-value pairs that `isIncluded` allows.
    public func filter(remaining: inout [Key: Value], _ isIncluded: (Element) throws -> Bool) rethrows -> [Key: Value] {
        try withoutActuallyEscaping(isIncluded) { try filter(remaining: &remaining, .where($0)) }
    }
}

extension Dictionary {
    public mutating func removeRandom() -> Element? {
        guard let random = randomElement() else { return nil }
        removeValue(forKey: random.key)
        return random
    }
}

// MARK: - Set

extension Set {
    public mutating func removeRandom() -> Element? {
        randomElement().flatMap { remove($0) }
    }
}

// MARK: - Array

extension Array {
    /// Creates a new array containing the specified number of a created elements.
    ///
    /// - Parameters:
    ///   - createElement: The closure to create elements.
    ///   - count: The number of times to create the value using passed in the
    ///     `create` closure. `count` must be zero or greater.
    @inlinable
    public init(count: Int, create createElement: () -> Element) {
        self = (0..<count).map { _ in createElement() }
    }
    
    /// Creates a new array containing the specified number of a created elements.
    ///
    /// - Parameters:
    ///   - createElement: The closure to create elements.
    ///   - count: The number of times to create the value using passed in the
    ///     `create` closure. `count` must be zero or greater.
    @inlinable
    public init(count: Int, create createElement: @autoclosure () -> Element) {
        self.init(count: count, create: createElement)
    }
}

// MARK: - Sequence

extension Sequence {
    /// Returns an array containing the pairs of the sequence's elements as `value` and
    /// results of mapping the given closure over the sequence's elements as `key`.
    ///
    /// - Parameter transform: A mapping closure. `transform` accepts an
    ///   element of this sequence as its parameter and returns a transformed
    ///   value that acts as `key` of resulting array.
    /// - Returns: An array containing key-value pairs of the elements of this sequence.
    ///
    /// - Complexity: O(*n*), where *n* is the length of the sequence.
    @inlinable public func keyedMap<Key>(_ transform: (Element) -> Key) -> [KeyValue<Key, Element>] {
        map { KeyValue(transform($0), $0) }
    }
    
    /// Returns an array containing the non-`nil` pairs of the sequence's elements as `value` and
    /// results of mapping the given closure over the sequence's elements as `key`.
    ///
    /// Use this method to receive an array of non-optional values when your
    /// transformation produces an optional value.
    ///
    /// - Parameter transform: A mapping closure. `transform` accepts an
    ///   element of this sequence as its parameter and returns a transformed
    ///   value that acts as `key` of resulting array or `nil` to exclude from results.
    /// - Returns: An array containing non-optional key-value pairs of the elements of this sequence.
    ///
    /// - Complexity: O(*n*), where *n* is the length of the sequence.
    @inlinable public func keyedCompactMap<Key>(_ transform: (Element) -> Key?) -> [KeyValue<Key, Element>] {
        compactMap { element in transform(element).flatMap { KeyValue($0, element) } }
    }
}

extension Sequence {
    @inlinable public func mutatingMap(mutate: (inout Element) throws -> Void) rethrows -> [Element] {
        try map {
            var mutated = $0
            try mutate(&mutated)
            return mutated
        }
    }
    
    /// Searches for first element that can be transformed with given predicate
    /// and returns transformed one.
    @inlinable public func firstMapped<T>(where transform: (Element) throws -> T?) rethrows -> T? {
        for element in self {
            if let mapped = try transform(element) {
                return mapped
            }
        }
        return nil
    }
}

extension Sequence {
    /// Returns an array containing, in order, the elements of the sequence
    /// that satisfy the given predicate.
    /// Collects unsatisfied elements into `remaining` array.
    ///
    /// In this example, `filter(_:)` is used to include only names shorter than
    /// five characters.
    ///
    ///     let cast = ["Vivien", "Marlon", "Kim", "Karl"]
    ///     var longNames: [String] = []
    ///     let shortNames = cast.filter(remaining: &longNames) { $0.count < 5 }
    ///     print(shortNames)
    ///     // Prints "["Kim", "Karl"]"
    ///     print(longNames)
    ///     // Prints "["Vivien", "Marlon"]"
    ///
    /// - Parameter isIncluded: A predicate that takes an element of the
    ///   sequence as its argument and returns a Boolean value indicating
    ///   whether the element should be included in the returned array.
    /// - Parameter remaining: An array to collect elements that are
    ///   not included into returned array.
    /// - Returns: An array of the elements that `isIncluded` allowed.
    ///
    /// - Complexity: O(*n*), where *n* is the length of the sequence.
    public func filter<Failure>(
        remaining: inout [Element],
        _ isIncluded: SBPredicate<Element, Failure>
    ) throws(Failure) -> [Element] {
        var filtered: [Element] = []
        for element in self {
            if try isIncluded.evaluate(element) {
                filtered.append(element)
            } else {
                remaining.append(element)
            }
        }
        return filtered
    }
    
    /// Returns an array containing, in order, the elements of the sequence
    /// that satisfy the given predicate.
    /// Collects unsatisfied elements into `remaining` array.
    ///
    /// In this example, `filter(_:)` is used to include only names shorter than
    /// five characters.
    ///
    ///     let cast = ["Vivien", "Marlon", "Kim", "Karl"]
    ///     var longNames: [String] = []
    ///     let shortNames = cast.filter(remaining: &longNames) { $0.count < 5 }
    ///     print(shortNames)
    ///     // Prints "["Kim", "Karl"]"
    ///     print(longNames)
    ///     // Prints "["Vivien", "Marlon"]"
    ///
    /// - Parameter isIncluded: A closure that takes an element of the
    ///   sequence as its argument and returns a Boolean value indicating
    ///   whether the element should be included in the returned array.
    /// - Parameter remaining: An array to collect elements that are
    ///   not included into returned array.
    /// - Returns: An array of the elements that `isIncluded` allowed.
    ///
    /// - Complexity: O(*n*), where *n* is the length of the sequence.
    @inlinable public func filter(
        remaining: inout [Element],
        _ isIncluded: (Element) throws -> Bool
    ) rethrows -> [Element] {
        try _withoutActuallyEscaping(isIncluded) { try filter(remaining: &remaining, $0) }
    }
}

extension Sequence {
    @inlinable public func sorted<T: Comparable>(by keyPath: KeyPath<Element, T>) -> [Element] {
        sorted {
            let lhs = $0[keyPath: keyPath]
            let rhs = $1[keyPath: keyPath]
            return lhs < rhs
        }
    }
}

extension Sequence {
    @inlinable public func sorted(options: String.CompareOptions) -> [Element] where Element: StringProtocol {
        sorted { $0.compare($1, options: options) == .orderedAscending }
    }
    
    @inlinable public func sorted<T: StringProtocol>(
        by keyPath: KeyPath<Element, T>,
        options: String.CompareOptions
    ) -> [Element] {
        sorted {
            let lhs = $0[keyPath: keyPath]
            let rhs = $1[keyPath: keyPath]
            return lhs.compare(rhs, options: options) == .orderedAscending
        }
    }
}

extension Sequence {
    /// Returns the result of combining the elements of the sequence into the dictionary
    /// using the given KeyPath to produce dictionary keys.
    ///
    /// Use the `reduce(into:_:)` method to produce a dictionary from the
    /// elements of an entire sequence.
    ///
    /// The `keyPath` KeyPath is applied sequentially to each element
    /// of the sequence and returns optional `Key`.
    /// If returned key is `nil`, it will not be included into resulting dictionary.
    ///
    /// - Parameters:
    ///   - initialDictionary: The value to use as the initial accumulating dictionary.
    ///   - keyPath: Keypath used to extract the `Key` from an element of the sequence.
    /// - Returns: The final accumulated dictionary. If the sequence has no elements,
    ///   the result is `initialDictionary`.
    @inlinable public func reduce<Key: Hashable>(
        into initialDictionary: [Key: Element] = [:],
        keyedBy keyPath: KeyPath<Element, Key?>
    ) -> [Key: Element] {
        reduce(into: initialDictionary) { $0[keyPath: keyPath] }
    }
    
    /// Returns the result of combining the elements of the sequence into the dictionary
    /// using the given KeyPath to produce dictionary keys.
    ///
    /// Use the `reduce(into:_:)` method to produce a dictionary from the
    /// elements of an entire sequence.
    ///
    /// The `keyPath` KeyPath is applied sequentially to each element
    /// of the sequence and returns `Key`.
    ///
    /// - Parameters:
    ///   - initialDictionary: The value to use as the initial accumulating dictionary.
    ///   - keyPath: Keypath used to extract the `Key` from an element of the sequence.
    /// - Returns: The final accumulated dictionary. If the sequence has no elements,
    ///   the result is `initialDictionary`.
    @inlinable public func reduce<Key: Hashable>(
        into initialDictionary: [Key: Element] = [:],
        keyedBy keyPath: KeyPath<Element, Key>
    ) -> [Key: Element] {
        reduce(into: initialDictionary) { $0[keyPath: keyPath] }
    }
    
    /// Returns the result of combining the elements of the sequence into the dictionary
    /// using the given closure to produce dictionary keys.
    ///
    /// Use the `reduce(into:_:)` method to produce a dictionary from the
    /// elements of an entire sequence.
    ///
    /// The `extractKey` closure is called sequentially with each element
    /// of the sequence and returns optional `Key`.
    /// If returned key is `nil`, it will not be included into resulting dictionary.
    ///
    /// - Parameters:
    ///   - initialDictionary: The value to use as the initial accumulating dictionary.
    ///   - extractKey: A closure that extracts the `Key` from an element of the sequence.
    /// - Returns: The final accumulated dictionary. If the sequence has no elements,
    ///   the result is `initialDictionary`.
    @inlinable public func reduce<Key: Hashable>(
        into initialDictionary: [Key: Element] = [:],
        keyedBy extractKey: (Element) throws -> Key?
    ) rethrows -> [Key: Element] {
        try reduce(into: initialDictionary) {
            if let key = try extractKey($1) {
                $0[key] = $1
            }
        }
    }
}

// MARK: - Collection

extension RangeReplaceableCollection {
    /// Bounds-safe access to the element at index.
    public subscript(safe index: Index) -> Element? {
        (startIndex..<endIndex).contains(index) ? self[index] : nil
    }
    
    public mutating func mutateElements(mutate: (inout Element) throws -> Void) rethrows {
        self = try Self(mutatingMap(mutate: mutate))
    }
    
    /// Creates new collection by appending `newElement` to the end of current one.
    @inlinable public func appending(_ newElement: Element) -> Self {
        var appended = Self(self)
        appended.append(newElement)
        return appended
    }
    
    /// Removes the first element from the array and returns it.`.
    /// If collection is empty, returns `nil`.
    /// Simply combination of `isEmpty` + `removeFirst`.
    @inlinable public mutating func popFirst() -> Element? {
        guard !isEmpty else { return nil }
        return removeFirst()
    }
    
    /// Removes all elements from the array and returns them.
    @inlinable public mutating func popAll(keepingCapacity: Bool = false) -> Self {
        defer { removeAll(keepingCapacity: keepingCapacity) }
        return Self(self)
    }
    
    /// Removes all elements from the array satisfying predicate and returns them.
    @inlinable public mutating func popAll(_ predicate: SBPredicate<Element, Never>) -> Self {
        var remaining: [Element] = []
        let removed = Self(filter(remaining: &remaining, predicate))
        self = Self(remaining)
        return removed
    }
    
    /// Removes all elements from the array satisfying predicate and returns them.
    @inlinable public mutating func popAll(where predicate: (Element) -> Bool) -> Self {
        _withoutActuallyEscaping(predicate) { popAll($0) }
    }
    
    /// Removes and returns the first element of the collection.
    ///
    /// - Returns: The first element of the collection or `nil` if collection is empty.
    @discardableResult
    @inlinable public mutating func removeFirst<Failure>(_ predicate: SBPredicate<Element, Failure>) throws(Failure) -> Element? {
        guard let idx = try predicate._call(firstIndex(where:)) else { return nil }
        return remove(at: idx)
    }
    
    /// Removes and returns the first element of the collection.
    ///
    /// - Returns: The first element of the collection or `nil` if collection is empty.
    @discardableResult
    public mutating func removeFirst(where predicate: (Element) throws -> Bool) rethrows -> Element? {
        try _withoutActuallyEscaping(predicate) { try removeFirst($0) }
    }
    
    /// Returns the first index where the specified value with specific property
    /// appears in the collection.
    ///
    /// - Parameter property: A property indicates whether the element
    ///   represents a match.
    /// - Returns: The index of the first element for which `property` matches
    ///   `true`. If no elements in the collection satisfy the given predicate,
    ///   returns `nil`.
    ///
    /// - Parameter keyPath: A KeyPath to property of the element to search for in the collection.
    /// - Parameter property: A property of the element to search for in the collection.
    /// - Returns: The first index where element with given `property` is found.
    ///   If element with given `property` is not found in the collection, returns `nil`.
    ///
    /// - Complexity: O(*n*), where *n* is the length of the collection.
    @inlinable public func firstIndex<Failure>(_ predicate: SBPredicate<Element, Failure>) throws(Failure) -> Index? {
        try predicate._call(firstIndex(where:))
    }
    
    /// Returns the indices of all the elements with specific property that are equal to the given
    /// `property`.
    ///
    /// - Parameter keyPath: A KeyPath to property of the element to look for in the collection.
    /// - Parameter element: A property of the element to look for in the collection.
    /// - Returns: A set of the indices of the elements whose properties are equal to `property`.
    ///
    /// - Complexity: O(*n*), where *n* is the length of the collection.
    @available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
    @inlinable public func indices<Failure>(
        _ predicate: SBPredicate<Element, Failure>
    ) throws(Failure) -> RangeSet<Index> {
        try predicate._call(indices(where:))
    }
    
    /// Adds a new element at the end of the array or updates the element if it exists.
    ///
    /// - Parameter element: The element to append to or update in the array.
    /// - Parameter predicate: A closure that takes an element as its argument
    ///   and returns a Boolean value that indicates whether the passed element
    ///   represents a match.
    /// - Returns: Previous element existed in array or `nil` if new element was appended.
    ///
    /// - Complexity: O(*n*), where *n* is the length of the collection.
    @discardableResult
    @inlinable public mutating func updateFirst<Failure>(
        _ element: Element,
        _ predicate: SBPredicate<Element, Failure>
    ) throws(Failure) -> Element? {
        if let idx = try predicate._call(firstIndex(where:)) {
            let oldValue = self[idx]
            replaceSubrange(idx..<index(after: idx), with: [element])
            return oldValue
        } else {
            append(element)
            return nil
        }
    }
    
    /// Adds a new element at the end of the array or updates the element if it exists.
    ///
    /// - Parameter element: The element to append to or update in the array.
    /// - Parameter keyPath: A KeyPath to property of the element to search for in the collection.
    /// - Returns: Previous element existed in array or `nil` if new element was appended.
    ///
    /// - Complexity: O(*n*), where *n* is the length of the collection.
    @discardableResult
    @inlinable public mutating func updateFirst<Property: Equatable>(
        _ element: Element,
        by keyPath: KeyPath<Element, Property>
    ) -> Element? {
        updateFirst(element, .equals(at: keyPath, to: element[keyPath: keyPath]))
    }
}

extension RangeReplaceableCollection where Index: FixedWidthInteger {
    public mutating func removeRandom() -> Element {
        let randomIndex = Index.random(in: startIndex..<endIndex)
        return remove(at: randomIndex)
    }
    
    public mutating func popRandom() -> Element? {
        guard !isEmpty else { return nil }
        return removeRandom()
    }
}

@usableFromInline
internal func _withoutActuallyEscaping<Value, Failure: Error, R>(
    _ predicate: (Value) throws(Failure) -> Bool,
    do body: (SBPredicate<Value, Failure>) throws(Failure) -> R
) throws(Failure) -> R {
    try withoutActuallyEscaping(consume predicate) { (predicate) throws(Failure) -> R in
        try body(.where(predicate))
    }
}

extension SBPredicate {
    /// Use with care only in functions that don't `rethrow` but `throws(Failure)`.
    @usableFromInline
    internal func _call<R>(_ body: ((Value) throws(Failure) -> Bool) throws -> R) throws(Failure) -> R {
        do {
            return try body(evaluate)
        } catch {
            throw error as! Failure
        }
    }
}
