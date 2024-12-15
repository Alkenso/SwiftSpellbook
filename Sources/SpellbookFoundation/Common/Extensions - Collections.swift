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
    public subscript(codingPath codingPath: [DictionaryCodingKey]) -> Any? {
        try? reader.read(codingPath: codingPath, as: Any.self)
    }
    
    /// Get value in nested dictionary using dot-separated key path.
    /// Keys in dictionary at keyPath componenets must be of String type
    /// Specific cases:
    ///     - Nested Array:
    ///         - pass [1] to follow the 1-st item in the nested array
    ///         - pass [*] to follow the last item in the nested array
    public subscript(dotPath dotPath: String) -> Any? {
        try? reader.read(dotPath: dotPath, as: Any.self)
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
    public mutating func popAll(where: (Element) -> Bool) -> Self {
        guard !isEmpty else { return [:] }
        var removed: [Key: Value] = [:]
        for element in self {
            if `where`(element) {
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
    public func filter(remaining: inout [Key: Value], _ isIncluded: (Element) throws -> Bool) rethrows -> [Key: Value] {
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
    public func keyedMap<Key>(_ transform: (Element) -> Key) -> [KeyValue<Key, Element>] {
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
    public func keyedCompactMap<Key>(_ transform: (Element) -> Key?) -> [KeyValue<Key, Element>] {
        compactMap { element in transform(element).flatMap { KeyValue($0, element) } }
    }
}

extension Sequence {
    public func mutatingMap(mutate: (inout Element) throws -> Void) rethrows -> [Element] {
        try map {
            var mutated = $0
            try mutate(&mutated)
            return mutated
        }
    }
    
    /// Searches for first element that can be transformed with given predicate
    /// and returns transformed one.
    public func firstMapped<T>(where transform: (Element) throws -> T?) rethrows -> T? {
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
    /// - Parameter isIncluded: A closure that takes an element of the
    ///   sequence as its argument and returns a Boolean value indicating
    ///   whether the element should be included in the returned array.
    /// - Parameter remaining: An array to collect elements that are
    ///   not included into returned array.
    /// - Returns: An array of the elements that `isIncluded` allowed.
    ///
    /// - Complexity: O(*n*), where *n* is the length of the sequence.
    public func filter(remaining: inout [Element], _ isIncluded: (Element) throws -> Bool) rethrows -> [Element] {
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
    public func sorted<T: Comparable>(by keyPath: KeyPath<Element, T>) -> [Element] {
        sorted {
            let lhs = $0[keyPath: keyPath]
            let rhs = $1[keyPath: keyPath]
            return lhs < rhs
        }
    }
}

extension Sequence {
    public func sorted(options: String.CompareOptions) -> [Element] where Element: StringProtocol {
        sorted { $0.compare($1, options: options) == .orderedAscending }
    }
    
    public func sorted<T: StringProtocol>(by keyPath: KeyPath<Element, T>, options: String.CompareOptions) -> [Element] {
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
    public func reduce<Key: Hashable>(
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
    public func reduce<Key: Hashable>(
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
    public func reduce<Key: Hashable>(
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
    public func appending(_ newElement: Element) -> Self {
        var appended = Self(self)
        appended.append(newElement)
        return appended
    }
    
    /// Removes the first element from the array and returns it.`.
    /// If collection is empty, returns `nil`.
    /// Simply combination of `isEmpty` + `removeFirst`.
    public mutating func popFirst() -> Element? {
        guard !isEmpty else { return nil }
        return removeFirst()
    }
    
    /// Removes all elements from the array and returns them.
    public mutating func popAll(keepingCapacity: Bool = false) -> Self {
        defer { removeAll(keepingCapacity: keepingCapacity) }
        return Self(self)
    }
    
    /// Removes all elements from the array satisfying predicate and returns them.
    public mutating func popAll(where: (Element) -> Bool) -> Self {
        var remaining: [Element] = []
        self = Self(filter(remaining: &remaining) { !`where`($0) })
        return Self(remaining)
    }
    
    /// Removes and returns the first element of the collection.
    ///
    /// - Returns: The first element of the collection or `nil` if collection is empty.
    @discardableResult
    public mutating func removeFirst(where predicate: (Element) throws -> Bool) rethrows -> Element? {
        guard let idx = try firstIndex(where: predicate) else { return nil }
        return remove(at: idx)
    }
}
