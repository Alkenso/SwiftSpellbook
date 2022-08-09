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

private let codableLogger = SCLogger.default(.codable)

extension Encodable {
    /// Encode value to json using specified encoder.
    /// Log failure to SwiftConvenience.Log
    public func encode(
        with encoder: ObjectEncoder<Self>,
        file: String = #file, _ function: String = #function, line: Int = #line, log: SCLog? = nil
    ) -> Data? {
        do {
            return try encoder.encode(self)
        } catch {
            (log ?? codableLogger).error("Encoding \(Self.self) to \(encoder.formatName) failed. Error: \(error)", file, function, line: line)
            return nil
        }
    }
}

public struct ObjectEncoder<T: Encodable> {
    public var formatName: String
    public var encode: (T) throws -> Data
    
    public init(name formatName: String, encode: @escaping (T) throws -> Data) {
        self.formatName = formatName
        self.encode = encode
    }
}

extension ObjectEncoder {
    public static func json(encoder: JSONEncoder = JSONEncoder()) -> Self {
        .init(name: "json", encode: encoder.encode)
    }
    
    public static func json(_ format: JSONEncoder.OutputFormatting) -> Self {
        let encoder = JSONEncoder()
        encoder.outputFormatting = format
        return .json(encoder: encoder)
    }
    
    public static func plist(encoder: PropertyListEncoder = PropertyListEncoder()) -> Self {
        .init(name: "plist", encode: encoder.encode)
    }
    
    public static func plist(_ format: PropertyListSerialization.PropertyListFormat) -> Self {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = format
        return .plist(encoder: encoder)
    }
}

extension Decodable {
    /// Initialize value from json using specified decoder.
    /// Log failure to SwiftConvenience.Log
    public init?(
        from data: Data, decoder: ObjectDecoder<Self>,
        file: String = #file, _ function: String = #function, line: Int = #line, log: SCLog? = nil
    ) {
        do {
            self = try decoder.decode(Self.self, data)
        } catch {
            (log ?? codableLogger).error("Decoding \(Self.self) from \(decoder.formatName) failed. Error: \(error)", file, function, line: line)
            return nil
        }
    }
}

public struct ObjectDecoder<T: Decodable> {
    public var formatName: String
    public var decode: (T.Type, Data) throws -> T
    
    public init(formatName: String = "custom", decode: @escaping (T.Type, Data) throws -> T) {
        self.formatName = formatName
        self.decode = decode
    }
}

extension ObjectDecoder {
    public static func json(decoder: JSONDecoder = JSONDecoder()) -> Self {
        .init(formatName: "json", decode: decoder.decode)
    }
    
    public static func plist(decoder: PropertyListDecoder = PropertyListDecoder()) -> Self {
        .init(formatName: "plist", decode: decoder.decode)
    }
}
