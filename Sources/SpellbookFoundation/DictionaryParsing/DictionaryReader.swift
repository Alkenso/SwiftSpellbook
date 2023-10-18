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

/// DictionaryReader is designed for convenient reading of dictionaries, especially with nested structure
/// ```
/// let person: [String: Any] = [
///     "name": "Bob",
///     "address": [
///         "city": "Miami",
///         "zip": 12345,
///     ],
///     "children": [
///         ["name": "Volodymyr", "age": 10],
///         ["name": "Julia", "age": 6],
///     ]
/// ]
/// var reader = DictionaryReader(person)
/// reader.contextDescription = "Parsing person properties from dict \(person)"
///
/// let name = try reader.get("name", as: String.self)
/// let childName = try reader.get(at: "children.[0].age", as: Int.self)
/// let city = try reader.get(at: ["address", "city"], as: String.self)
/// ```
public struct DictionaryReader<Key: Hashable, Value> {
    public let dictionary: [Key: Value]
    
    /// If set, context description is appended to any error thrown while reading the dictionary.
    public var context: String?
    
    /// If set, the error will contain the whole dictionary inside.
    public var errorContainsDictionary = false
    
    public init(_ dictionary: [Key: Value]) {
        self.dictionary = dictionary
    }
    
    /// Get value for key
    /// ```
    /// // `name` has type `Any` here b/c the `reader` reads from `[String: Any]`
    /// let name = try reader.get("name")
    /// ```
    ///
    /// - Returns: Value for given key if it exists
    /// - Throws: `DictionaryCodingError.keyNotFound`
    public func read(key: Key) throws -> Value {
        try read(key: key) { $0 }
    }
    
    /// Get value for key, converting the value into desired type
    /// ```
    /// // `name` has type `String`
    /// let name = try reader.get("name") { $0 as? String }
    /// ```
    ///
    /// - Returns: Value for given key
    /// - Throws: `DictionaryCodingError.keyNotFound` if key does not exist
    /// - Throws: `DictionaryCodingError.typeMismatch` if value for given key cannot be converted into desired type
    public func read<R>(key: Key, transform: (Value) -> R?) throws -> R {
        let codingKey = DictionaryCodingKey.key(key)
        guard let value = dictionary[key] else {
            try throwNotFound(for: codingKey, size: dictionary.count, codingPath: [codingKey])
        }
        guard let transformed = transform(value) else {
            try throwInvalidResultType(for: value, expectedType: R.self, codingPath: [codingKey])
        }
        return transformed
    }
    
    /// Get value for key, converting the value into desired type
    /// ```
    /// // `name` has type `String`
    /// let name = try reader.get("name", as: String.self)
    /// ```
    ///
    /// - Returns: Value for given key
    /// - Throws: `DictionaryCodingError.keyNotFound` if key does not exist
    /// - Throws: `DictionaryCodingError.typeMismatch` if value for given key cannot be converted into desired type
    public func read<R>(key: Key, as: R.Type) throws -> R {
        try read(key: key) { $0 as? R }
    }
    
    /// Get value for `dotPath`, converting the value it into desired type
    /// ```
    /// let childAge = try reader.get(at: "name.children.[0].age") { $0 as? String }
    /// ```
    ///
    /// - Parameters:
    ///     - dotPath: dot-separated string representing complex path to the desired value.
    ///       dotPath components can be:
    ///       - usual strings: "name.address.city"
    ///       - array index: "name.children.[0].name"
    ///       - last array index: "name.children.[*].name"
    ///     - transform: closure that optionally converts found value into desired type
    /// - Returns: Value for `dotPath`
    /// - Throws: `DictionaryCodingError.invalidArgument` if dotPath is empty
    /// - Throws: `DictionaryCodingError.keyNotFound` if key does not exist
    /// - Throws: `DictionaryCodingError.typeMismatch` if value for given key cannot be converted into resulting type
    public func read<R>(dotPath: String, transform: (Any) -> R?) throws -> R {
        let components = DictionaryCodingKey.parse(dotPath: dotPath)
        return try read(codingPath: components, transform: transform)
    }
    
    /// Get value for `dotPath`, converting the value it into desired type
    /// ```
    /// let childAge = try reader.get(at: "name.children.[0].age", as: String.self)
    /// ```
    ///
    /// For more details, see `get(at:transform:)`
    public func read<R>(dotPath: String, as: R.Type) throws -> R {
        try read(dotPath: dotPath) { $0 as? R }
    }
    
    /// Get value for `codingPath`, converting the value it into desired type
    /// ```
    /// let childAge = try reader.get(at: ["name", "children", .index(0), "age"]) { $0 as? String }
    /// ```
    ///
    /// - Parameters:
    ///     - codingPath: array of specific DictionaryCodingKey items
    ///       representing complex path to the desired value.
    ///       codingPath components can be:
    ///       - usual strings: "name", automatically converted to `.key`
    ///       - `key`: path component representing key in the dictionary
    ///       - `index`: path component representing index in the array
    ///       - `index(.max)`: path component representing last index in the array
    ///     - transform: closure that optionally converts found value into desired type
    /// - Returns: Value for `codingPath`
    /// - Throws:
    ///     - `DictionaryCodingError.invalidArgument` if codingPath is empty
    ///     - `DictionaryCodingError.keyNotFound` if key does not exist
    ///     - `DictionaryCodingError.typeMismatch` if value for given key cannot be converted into resulting type
    public func read<R>(codingPath: [DictionaryCodingKey], transform: (Any) -> R?) throws -> R {
        guard !codingPath.isEmpty else {
            try throwError(
                .invalidArgument, codingPath: codingPath,
                error: CommonError.invalidArgument(
                    arg: "codingPath", invalidValue: codingPath,
                    description: "Failed to get value at empty codingPath"
                )
            )
        }
        
        var lastItem: Any = dictionary
        var lastItemKeyPath: [DictionaryCodingKey] = []
        for keyPathComponent in codingPath {
            lastItemKeyPath.append(keyPathComponent)
            
            switch keyPathComponent {
            case .key(let key):
                guard let dict = lastItem as? [AnyHashable: Any] else {
                    try throwInvalidContainer(for: lastItem, expectedType: [AnyHashable: Any].self, codingPath: lastItemKeyPath)
                }
                guard let nestedItem = dict[key] else {
                    try throwNotFound(for: keyPathComponent, size: dict.count, codingPath: lastItemKeyPath)
                }
                lastItem = nestedItem
            case .index(let index):
                guard let arr = lastItem as? [Any] else {
                    try throwInvalidContainer(for: lastItem, expectedType: [Any].self, codingPath: lastItemKeyPath)
                }
                guard let nestedItem = (index != .max ? arr[safe: index] : arr.last) else {
                    try throwNotFound(for: keyPathComponent, size: arr.count, codingPath: lastItemKeyPath)
                }
                lastItem = nestedItem
            }
        }
        
        guard let resultItem = transform(lastItem) else {
            try throwInvalidResultType(for: lastItem, expectedType: R.self, codingPath: codingPath)
        }
        
        return resultItem
    }
    
    /// Get value for `codingPath`, converting the value it into desired type
    /// ```
    /// let childAge = try reader.get(at: ["name", "children", .index(0), "age"], as: String.self)
    /// ```
    ///
    /// For more details, see `get(at:transform:)`
    public func read<R>(codingPath: [DictionaryCodingKey], as: R.Type) throws -> R {
        try read(codingPath: codingPath) { $0 as? R }
    }
    
    private func throwInvalidContainer<T>(
        for item: Any, expectedType: T.Type, codingPath: [DictionaryCodingKey]
    ) throws -> Never {
        let error = CommonError.cast(name: "Container type to read from", item, to: T.self)
        try throwError(.typeMismatch, codingPath: codingPath, error: error)
    }
    
    private func throwNotFound(
        for key: DictionaryCodingKey, size: Int, codingPath: [DictionaryCodingKey]
    ) throws -> Never {
        let error: Error
        switch key {
        case .key(let key):
            error = CommonError.notFound(what: "value for key", value: key)
        case .index(let index):
            error = CommonError.outOfRange(what: "Index", value: index, where: "array", limitValue: size)
        }
        try throwError(.keyNotFound, codingPath: codingPath, error: error)
    }
    
    private func throwInvalidResultType<T>(
        for item: Any, expectedType: T.Type, codingPath: [DictionaryCodingKey]
    ) throws -> Never {
        let error = CommonError.cast(name: "Result value", item, to: T.self)
        try throwError(.typeMismatch, codingPath: codingPath, error: error)
    }
    
    private func throwError(
        _ code: DictionaryCodingError.Code, codingPath: [DictionaryCodingKey], error underlyingError: Error
    ) throws -> Never {
        throw DictionaryCodingError(
            code: code, codingPath: codingPath,
            description: "Failed to read from dictionary",
            underlyingError: underlyingError,
            context: context,
            relatedObject: errorContainsDictionary ? dictionary : nil
        )
    }
}

extension DictionaryReader: ObjectBuilder {}
