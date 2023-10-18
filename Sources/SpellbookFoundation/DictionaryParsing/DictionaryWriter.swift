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

/// DictionaryWriter is designed for convenient modifying the dictionaries with nested structure
/// ```
/// var person: [String: Any] = [
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
/// var writer = DictionaryWriter(person) { person = $0 }
/// writer.contextDescription = "Writing to person properties"
///
/// // insert value "+1(234)567890" for `phone` key into `address` sub-dict
/// try writer.insert("+1(234)567890", at: "address.phone")
///
/// // change last child age to `22`
/// try writer.insert(22, at: ["children", .index(.max), "age")
///
/// // accessing the resulting dictionary:
/// // - person: because is was captured into `onUpdate` closure in the writer's `init`
/// // - writer.dictionary: access writer's dictionary copy
/// ```
public struct DictionaryWriter<Key: Hashable, Value> {
    public private(set) var dictionary: [Key: Value]
    public var onUpdate: (([Key: Value]) -> Void)?
    
    /// If set, context description is appended to any error thrown while inserting into the dictionary
    public var context: String?
    
    /// If set, the error will contain the whole dictionary inside.
    public var errorContainsDictionary = false
    
    /// Creates `DictionaryWriter` with dictionary and update closure
    /// - Parameters:
    ///     - dictionary: initial dictionary
    ///     - onUpdate: closure called each time the dictionary is updated.
    ///                 Convenient to use to immediately update dictionary in outer context (see example above)
    public init(_ dictionary: [Key: Value], onUpdate: (([Key: Value]) -> Void)? = nil) {
        self.dictionary = dictionary
        self.onUpdate = onUpdate
    }
    
    /// Inserts value into the dictionary at dot-separated key path
    /// - Parameters:
    ///     - value: value to insert into the dictionary
    ///     - dotPath: dot-separated string representing complex path to the desired value.
    ///       dotPath components can be:
    ///       - usual strings: "name.address.city"
    ///       - array index: "name.children.[0].name"
    ///       - last array index: "name.children.[*].name"
    /// - Throws: `DictionaryCodingError.invalidArgument` if dotPath is empty
    /// - Throws: `DictionaryCodingError.keyNotFound` if array index out of range
    /// - Throws: `DictionaryCodingError.typeMismatch` if value for given key cannot be converted
    /// - Note: If intermediate array is empty and dotPath component is `[0]` or `[*]`,
    ///         the array will be appended
    ///
    /// If nested dictionaries or arrays does not exist,
    ///         they are created as [AnyHashable: Any] and [Any] respectively
    public mutating func insert(value: Any, dotPath: String) throws {
        let components = DictionaryCodingKey.parse(dotPath: dotPath)
        return try insert(value: value, codingPath: components)
    }
    
    /// Inserts value into the dictionary at coding path
    /// - Parameters:
    ///     - value: value to insert into the dictionary
    ///     - codingPath: array of specific DictionaryCodingKey items
    ///       representing complex path to the desired value.
    ///       codingPath components can be:
    ///       - usual strings: "name", automatically converted to `.key`
    ///       - `key`: path component representing key in the dictionary
    ///       - `index`: path component representing index in the array
    ///       - `index(.max)`: path component representing last index in the array
    /// - Throws: `DictionaryCodingError.invalidArgument` if codingPath is empty
    /// - Throws: `DictionaryCodingError.keyNotFound` if array index out of range
    /// - Throws: `DictionaryCodingError.typeMismatch` if value for given key cannot be converted
    ///           into intermediate collection type
    ///
    /// - Note: If intermediate array is empty and coding path key is `.index(0)` or `.index(.max)`,
    ///         the array will be appended
    ///
    /// If nested dictionaries or arrays does not exist,
    ///         they are created as [AnyHashable: Any] and [Any] respectively
    public mutating func insert(value: Any, codingPath: [DictionaryCodingKey]) throws {
        guard !codingPath.isEmpty else {
            try throwError(
                .invalidArgument, codingPath: codingPath,
                error: CommonError.invalidArgument(
                    arg: "codingPath", invalidValue: codingPath,
                    description: "Failed to insert value at empty codingPath"
                )
            )
        }
        
        let updated = try insert(into: dictionary, at: codingPath, value: value)
        guard let dict = updated as? [Key: Value] else {
            try throwInvalidContainer(actual: updated, expectedType: [Key: Value].self, codingPath: [])
        }
        
        dictionary = dict
        onUpdate?(dictionary)
    }
    
    private func insert(into: Any?, at keyPath: [DictionaryCodingKey], value: Any) throws -> Any {
        switch keyPath[0] {
        case .key(let key):
            let collection = into ?? [AnyHashable: Any]()
            guard var dictionary = collection as? [AnyHashable: Any] else {
                try throwInvalidContainer(actual: collection, expectedType: [AnyHashable: Any].self, codingPath: keyPath)
            }
            if keyPath.count == 1 {
                dictionary[key] = value
            } else {
                dictionary[key] = try insert(into: dictionary[key], at: Array(keyPath.dropFirst()), value: value)
            }
            return dictionary
        case .index(let index):
            let collection = into ?? [Any]()
            guard var array = collection as? [Any] else {
                try throwInvalidContainer(actual: collection, expectedType: [Any].self, codingPath: keyPath)
            }
            
            let isFirstOrLast = index == 0 || index == .max
            let existingItemAtIndex = index != .max ? array[safe: index] : array.last
            if existingItemAtIndex == nil, !isFirstOrLast {
                try throwOutOfRange(index: index, size: array.count, codingPath: keyPath)
            }
            
            let newItem: Any
            if keyPath.count == 1 {
                newItem = value
            } else {
                newItem = try insert(into: existingItemAtIndex, at: Array(keyPath.dropFirst()), value: value)
            }
            
            if array.isEmpty {
                array.append(newItem)
            } else {
                array[index] = newItem
            }
            return array
        }
    }
    
    private func throwInvalidContainer<T>(
        actual: Any, expectedType: T.Type, codingPath: [DictionaryCodingKey]
    ) throws -> Never {
        let error = CommonError.cast(name: "container", actual, to: expectedType)
        try throwError(.typeMismatch, codingPath: codingPath, error: error)
    }
    
    private func throwOutOfRange(index: Int, size: Int, codingPath: [DictionaryCodingKey]) throws -> Never {
        let error = CommonError.outOfRange(what: "index", value: index, limitValue: size)
        try throwError(.keyNotFound, codingPath: codingPath, error: error)
    }
    
    private func throwError(
        _ code: DictionaryCodingError.Code, codingPath: [DictionaryCodingKey], error underlyingError: Error
    ) throws -> Never {
        throw DictionaryCodingError(
            code: code, codingPath: codingPath,
            description: "Failed to write to dictionary",
            underlyingError: underlyingError,
            context: context,
            relatedObject: errorContainsDictionary ? dictionary : nil
        )
    }
}

extension DictionaryWriter: ObjectBuilder {}
