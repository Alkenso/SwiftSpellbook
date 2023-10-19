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

private let codableLogger = SpellbookLogger.internal(category: "Codable")

extension Encodable {
    /// Encode value to json using specified encoder.
    /// Log failure to SpellbookLog.
    public func encode(
        with encoder: ObjectEncoder<Self>,
        file: StaticString = #file, _ function: StaticString = #function, line: Int = #line, log: SpellbookLog? = nil
    ) -> Data? {
        do {
            return try encoder.encode(self)
        } catch {
            (log ?? codableLogger).error("Encoding \(Self.self) to \(encoder.formatName) failed. Error: \(error)", file, function, line: line)
            return nil
        }
    }
}

public struct ObjectEncoder<T> {
    public var formatName: String
    public var encode: (T) throws -> Data
    
    public init(name formatName: String, encode: @escaping (T) throws -> Data) {
        self.formatName = formatName
        self.encode = encode
    }
}

extension ObjectEncoder where T: Encodable {
    public static func json(type: T.Type = T.self, encoder: JSONEncoder = JSONEncoder()) -> Self {
        .init(name: "json", encode: encoder.encode)
    }
    
    public static func json(type: T.Type = T.self, _ formatting: JSONEncoder.OutputFormatting) -> Self {
        let encoder = JSONEncoder()
        encoder.outputFormatting = formatting
        return .json(encoder: encoder)
    }
    
    public static func plist(type: T.Type = T.self, encoder: PropertyListEncoder = PropertyListEncoder()) -> Self {
        .init(name: "plist", encode: encoder.encode)
    }
    
    public static func plist(type: T.Type = T.self, _ format: PropertyListSerialization.PropertyListFormat) -> Self {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = format
        return .plist(encoder: encoder)
    }
}

extension ObjectEncoder {
    public static func foundationJSON(type: T.Type = T.self, _ options: JSONSerialization.WritingOptions = []) -> Self {
        .init(name: "json") { try JSONSerialization.data(withJSONObject: $0, options: options) }
    }
    
    public static func foundationPlist(type: T.Type = T.self, _ format: PropertyListSerialization.PropertyListFormat) -> Self {
        .init(name: "plist") { try PropertyListSerialization.data(fromPropertyList: $0, format: format, options: 0) }
    }
}

extension Decodable {
    /// Initialize value from json using specified decoder.
    /// Log failure to SpellbookLog.
    public init?(
        from data: Data, decoder: ObjectDecoder<Self>,
        file: StaticString = #file, _ function: StaticString = #function, line: Int = #line, log: SpellbookLog? = nil
    ) {
        do {
            self = try decoder.decode(Self.self, data)
        } catch {
            (log ?? codableLogger).error("Decoding \(Self.self) from \(decoder.formatName) failed. Error: \(error)", file, function, line: line)
            return nil
        }
    }
}

public struct ObjectDecoder<T> {
    public var formatName: String
    public var decode: (T.Type, Data) throws -> T
    
    public init(formatName: String = "custom", decode: @escaping (T.Type, Data) throws -> T) {
        self.formatName = formatName
        self.decode = decode
    }
}

extension ObjectDecoder where T: Decodable {
    public static func json(_ type: T.Type = T.self, decoder: JSONDecoder = JSONDecoder()) -> Self {
        .init(formatName: "json", decode: decoder.decode)
    }
    
    public static func plist(_ type: T.Type = T.self, decoder: PropertyListDecoder = PropertyListDecoder()) -> Self {
        .init(formatName: "plist", decode: decoder.decode)
    }
}

extension ObjectDecoder {
    public static func foundationJSON(_ type: T.Type = T.self, options: JSONSerialization.ReadingOptions = []) -> Self {
        .init(formatName: "json") {
            let object = try JSONSerialization.jsonObject(with: $1, options: options)
            return try (object as? T).get(CommonError.cast(name: "JSON object", object, to: $0))
        }
    }
    
    public static func foundationPlist(_ type: T.Type = T.self, options: PropertyListSerialization.ReadOptions = []) -> Self {
        .init(formatName: "plist") {
            let object = try PropertyListSerialization.propertyList(from: $1, options: options, format: nil)
            return try (object as? T).get(CommonError.cast(name: "Plist object", object, to: $0))
        }
    }
}

// MARK: Any + Codable

/// Property wrapper around object compatible with PropertyListSerialization routines.
///
/// Assume we have some struct we want to be Codable:
/// ```
/// struct Foo: Codable {
///     var name: String
///     var attributes: [String: Any] // NOT Codable-compatible
/// }
/// ```
/// [String: Any] is not Codable compatible because Any is not Codable.
/// But in some situations we as developers are sure that all `attributes` content is plist-compatible type.
/// In such case we can use `PropertyListSerializable` property wrapper:
/// ```
/// struct Foo: Codable {
///     var name: String
///     @PropertyListSerializable var attributes: [String: Any] // OK
/// }
/// ```
/// Under the hood, `PropertyListSerializable` stores the `attributes` as Data
/// using `PropertyListSerialization` functions to perform data<->object convertions.
@propertyWrapper
public struct PropertyListSerializable<T> {
    public var wrappedValue: T
    
    public init(wrappedValue: T) {
        self.wrappedValue = wrappedValue
    }
}

extension PropertyListSerializable: Serializable {
    fileprivate static var formatName: String { "plist" }
    
    fileprivate static func isValidObject(_ object: Any) -> Bool {
        PropertyListSerialization.propertyList(object, isValidFor: .xml)
    }
    
    fileprivate static func objectToData(_ object: Any) throws -> Data {
        try PropertyListSerialization.data(fromPropertyList: object, format: .xml, options: 0)
    }
    
    fileprivate static func dataToObject(_ data: Data) throws -> Any {
        try PropertyListSerialization.propertyList(from: data, format: nil)
    }
}

/// Property wrapper around object compatible with JSONSerialization routines.
///
/// Assume we have some struct we want to be Codable:
/// ```
/// struct Foo: Codable {
///     var name: String
///     var attributes: [String: Any] // NOT Codable-compatible
/// }
/// ```
/// [String: Any] is not Codable compatible because Any is not Codable.
/// But in some situations we as developers are sure that all `attributes` content is JSON-compatible type.
/// In such case we can use `JSONSerializable` property wrapper:
/// ```
/// struct Foo: Codable {
///     var name: String
///     @JSONSerializable var attributes: [String: Any] // OK
/// }
/// ```
/// Under the hood, `JSONSerializable` stores the `attributes` as Data
/// using `JSONSerialization` functions to perform data<->object convertions.
@propertyWrapper
public struct JSONSerializable<T> {
    public var wrappedValue: T
    
    public init(wrappedValue: T) {
        self.wrappedValue = wrappedValue
    }
}

extension JSONSerializable: Serializable {
    fileprivate static var formatName: String { "json" }
    
    fileprivate static func isValidObject(_ object: Any) -> Bool {
        JSONSerialization.isValidJSONObject(object)
    }
    
    fileprivate static func objectToData(_ object: Any) throws -> Data {
        try JSONSerialization.data(withJSONObject: object)
    }
    
    fileprivate static func dataToObject(_ data: Data) throws -> Any {
        try JSONSerialization.jsonObject(with: data)
    }
}

private protocol Serializable: Codable {
    associatedtype T
    var wrappedValue: T { get set }
    init(wrappedValue: T)
    
    static var formatName: String { get }
    static func isValidObject(_ object: Any) -> Bool
    static func objectToData(_ object: Any) throws -> Data
    static func dataToObject(_ data: Data) throws -> Any
}

extension Serializable {
    public init(from decoder: Decoder) throws {
        let data = try Data(from: decoder)
        do {
            let any = try Self.dataToObject(data)
            guard let value = any as? T else { throw CommonError.cast(any, to: T.self) }
            self.init(wrappedValue: value)
        } catch {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Invalid \(Self.formatName) data",
                    underlyingError: error
                )
            )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        guard Self.isValidObject(wrappedValue) else {
            throw EncodingError.invalidValue(
                wrappedValue,
                EncodingError.Context(
                    codingPath: [],
                    debugDescription: "Value of type \(T.self) is not valid for \(Self.formatName) encoding"
                )
            )
        }
        
        let data: Data
        do {
            data = try Self.objectToData(wrappedValue)
        } catch {
            throw EncodingError.invalidValue(
                wrappedValue,
                EncodingError.Context(
                    codingPath: encoder.codingPath,
                    debugDescription: "Invalid \(Self.formatName) data",
                    underlyingError: error
                )
            )
        }
        try data.encode(to: encoder)
    }
}
