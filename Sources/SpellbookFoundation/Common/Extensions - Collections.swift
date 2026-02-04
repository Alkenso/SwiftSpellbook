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
    public mutating func popAll(where predicate: (Element) -> Bool) -> Self {
        guard !isEmpty else { return [:] }
        var removed: [Key: Value] = [:]
        for element in self {
            if predicate(element) {
                removeValue(forKey: element.key)
                removed[element.key] = element.value
            }
        }
        return removed
    }
}

extension Dictionary {
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
    public func filter<E: Error>(
        remaining: inout [Key: Value],
        _ isIncluded: (Element) throws(E) -> Bool
    ) throws(E) -> [Key: Value] {
        var filtered: [Key: Value] = [:]
        for (key, value) in self {
            if try isIncluded((key, value)) {
                filtered[key] = value
            } else {
                remaining[key] = value
            }
        }
        return filtered
    }
}

extension Dictionary {
    public mutating func removeRandom() -> Element? {
        guard let random = randomElement() else { return nil }
        removeValue(forKey: random.key)
        return random
    }
}

extension Dictionary {
    @inlinable
    public subscript(key: Key, create newValue: @autoclosure () -> Value) -> Value {
        mutating get {
            if let value = self[key] {
                return value
            } else {
                let value = newValue()
                self[key] = value
                return value
            }
        }
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

extension Array {
    public mutating func stableSort<E: Error>(by areInIncreasingOrder: (Element, Element) throws(E) -> Bool) throws(E) {
        self = try stableSorted(by: areInIncreasingOrder)
    }
    
    public mutating func stableSort<Property: Comparable>(by keyPath: KeyPath<Element, Property>) {
        self = stableSorted(by: keyPath)
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
    
    public func recursiveMap<U, C, E: Error>(
        at children: (Element) -> C,
        _ transform: (Element) throws(E) -> U
    ) throws(E) -> [U] where C: Collection, C.Element == Element {
        try recursiveCompactMap(at: children, transform)
    }
    
    public func recursiveCompactMap<U, C, E: Error>(
        at children: (Element) -> C?,
        _ transform: (Element) throws(E) -> U?
    ) throws(E) -> [U] where C: Collection, C.Element == Element {
        var transformed: [U] = []
        for element in self {
            if let transformedElement = try transform(element) {
                transformed.append(transformedElement)
            }
            if let childrenElements = children(element) {
                transformed.append(contentsOf: try childrenElements.recursiveCompactMap(at: children, transform))
            }
        }
        return transformed
    }
    
    @inlinable
    public func mutatingMap<E: Error>(mutate: (inout Element) throws(E) -> Void) throws(E) -> [Element] {
        try map { element throws(E) in
            var mutated = element
            try mutate(&mutated)
            return mutated
        }
    }
    
    /// Searches for first element that can be transformed with given predicate
    /// and returns transformed one.
    @inlinable
    public func firstMapped<T, E: Error>(where transform: (Element) throws(E) -> T?) throws(E) -> T? {
        for element in self {
            if let mapped = try transform(element) {
                return mapped
            }
        }
        return nil
    }
    
    @inlinable
    public func min<T: Comparable>(by keyPath: KeyPath<Element, T>) -> Element? {
        self.min { $0[keyPath: keyPath] < $1[keyPath: keyPath] }
    }
    
    @inlinable
    public func max<T: Comparable>(by keyPath: KeyPath<Element, T>) -> Element? {
        self.max { $0[keyPath: keyPath] < $1[keyPath: keyPath] }
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
    /// - Parameter isIncluded: A closure that takes an element of the
    ///   sequence as its argument and returns a Boolean value indicating
    ///   whether the element should be included in the returned array.
    /// - Parameter remaining: An array to collect elements that are
    ///   not included into returned array.
    /// - Returns: An array of the elements that `isIncluded` allowed.
    ///
    /// - Complexity: O(*n*), where *n* is the length of the sequence.
    @inlinable public func filter<E: Error>(
        remaining: inout [Element],
        _ isIncluded: (Element) throws(E) -> Bool
    ) throws(E) -> [Element] {
        var filtered: [Element] = []
        for element in self {
            if try isIncluded(element) {
                filtered.append(element)
            } else {
                remaining.append(element)
            }
        }
        return filtered
    }
}

extension Sequence {
    @inlinable
    public func sorted<T: Comparable>(by keyPath: KeyPath<Element, T>) -> [Element] {
        sorted {
            let lhs = $0[keyPath: keyPath]
            let rhs = $1[keyPath: keyPath]
            return lhs < rhs
        }
    }
    
    public func stableSorted<E: Error>(
        by areInIncreasingOrder: (Element, Element) throws(E) -> Bool
    ) throws(E) -> [Element] {
        do {
            return try enumerated()
                .sorted { lhs, rhs -> Bool in
                    try areInIncreasingOrder(lhs.element, rhs.element) ||
                    (lhs.offset < rhs.offset && !areInIncreasingOrder(rhs.element, lhs.element))
                }
                .map(\.element)
        } catch {
            throw error as! E
        }
    }
    
    public func stableSorted<Property: Comparable>(by keyPath: KeyPath<Element, Property>) -> [Element] {
        stableSorted { $0[keyPath: keyPath] < $1[keyPath: keyPath] }
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
    @inlinable public func reduce<Key: Hashable, E: Error>(
        into initialDictionary: [Key: Element] = [:],
        keyedBy extractKey: (Element) throws(E) -> Key?
    ) throws(E) -> [Key: Element] {
        try _typedRethrow(error: E.self) {
            try reduce(into: initialDictionary) {
                if let key = try extractKey($1) {
                    $0[key] = $1
                }
            }
        }
    }
}

// MARK: - Collection

extension Collection {
    /// Bounds-safe access to the element at index.
    public subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
    
    @inlinable public func firstAfter(_ element: Element) -> Element? where Element: Equatable {
        firstAfter(element, by: ==)
    }
    
    @inlinable public func firstAfter(_ element: Element, by: (Element, Element) -> Bool) -> Element? {
        guard let index = firstIndex(where: { by($0, element) }) else { return nil }
        let after = self.index(after: index)
        return after < endIndex ? self[after] : nil
    }
}

extension RangeReplaceableCollection {
    public mutating func mutateElements<E: Error>(mutate: (inout Element) throws(E) -> Void) throws(E) {
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
    @inlinable public mutating func popAll<E: Error>(where predicate: (Element) throws(E) -> Bool) throws(E) -> Self {
        var remaining: [Element] = []
        let removed = try Self(filter(remaining: &remaining, predicate))
        self = Self(remaining)
        return removed
    }
    
    /// Removes and returns the first element of the collection.
    ///
    /// - Returns: The first element of the collection or `nil` if collection is empty.
    @discardableResult
    public mutating func removeFirst<E: Error>(where predicate: (Element) throws(E) -> Bool) throws(E) -> Element? {
        try _typedRethrow(error: E.self) {
            guard let idx = try firstIndex(where: predicate) else { return nil }
            return remove(at: idx)
        }
    }
    
    /// Appends a new element to the collection or updates the element if it exists.
    ///
    /// - Parameter element: The element to append to or update in the collection.
    /// - Parameter keyPath: A KeyPath to property of the element to search for in the collection.
    /// - Returns: Previous element existed in the collection or `nil` if new element was appended.
    ///
    /// - Complexity: O(*n*), where *n* is the length of the collection.
    @discardableResult
    @inlinable public mutating func updateFirst<E: Error>(
        _ element: Element,
        where equality: (Element) throws(E) -> Bool
    ) throws(E) -> Element? {
        try _typedRethrow(error: E.self) {
            if let idx = try firstIndex(where: equality) {
                let oldValue = self[idx]
                replaceSubrange(idx..<index(after: idx), with: [element])
                return oldValue
            } else {
                append(element)
                return nil
            }
        }
    }
    
    @discardableResult
    @inlinable public mutating func updateFirst<Property: Equatable>(
        _ element: Element,
        by keyPath: KeyPath<Element, Property>
    ) -> Element? {
        let lhs = element[keyPath: keyPath]
        return updateFirst(element, where: { lhs == $0[keyPath: keyPath] })
    }
    
    public mutating func rotate(shift: Int = 1) {
        self = rotated(shift: shift)
    }
    
    public func rotated(shift: Int = 1) -> Self {
        let shiftCount = abs(shift % count)
        guard !isEmpty, shiftCount != 0 else { return self }
        
        if shift > 0 {
            return Self(dropFirst(shiftCount) + prefix(shiftCount))
        } else {
            return Self(suffix(shiftCount) + dropLast(shiftCount))
        }
    }
    
    @inlinable public mutating func removeRandom() -> Element {
        indices.randomElement().flatMap { remove(at: $0) } ?? removeFirst()
    }
    
    @inlinable public mutating func popRandom() -> Element? {
        guard !isEmpty else { return nil }
        return removeRandom()
    }
    
    public func removingDuplicates<E: Error>(by isEqual: (Element, Element) throws(E) -> Bool) throws(E) -> Self {
        try _typedRethrow(error: E.self) {
            try reduce(into: Self()) { result, element in
                if try !result.contains(where: { try isEqual($0, element) }) {
                    result.append(element)
                }
            }
        }
    }
    
    public mutating func removeDuplicates<E: Error>(by isEqual: (Element, Element) throws(E) -> Bool) throws(E) {
        self = try removingDuplicates(by: isEqual)
    }
    
    public func removingDuplicates() -> Self where Element: Equatable {
        removingDuplicates(by: ==)
    }
    
    public mutating func removeDuplicates() where Element: Equatable {
        self = removingDuplicates()
    }
    
    public mutating func removeDuplicates() where Element: Hashable {
        self = removingDuplicates()
    }
    
    public func removingDuplicates() -> Self where Element: Hashable {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}

extension BidirectionalCollection {
    /// Searches for last element that can be transformed with given predicate
    /// and returns transformed one.
    /// Combination of `reversed` and `firstMapped`.
    @inlinable
    public func lastMapped<T, E: Error>(where transform: (Element) throws(E) -> T?) throws(E) -> T? {
        for element in reversed() {
            if let mapped = try transform(element) {
                return mapped
            }
        }
        return nil
    }
    
    @inlinable public func firstBefore(_ element: Element) -> Element? where Element: Equatable {
        firstBefore(element, by: ==)
    }
    
    @inlinable public func firstBefore(_ element: Element, by: (Element, Element) -> Bool) -> Element? {
        guard let index = firstIndex(where: { by($0, element) }), index > startIndex else { return nil }
        let before = self.index(before: index)
        return self[before]
    }
}
