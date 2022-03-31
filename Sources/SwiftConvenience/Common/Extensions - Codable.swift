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

extension Encodable {
    /// Encode value to json using specified encoder.
    /// Log failure to SwiftConvenience.Log
    public func json(
        encoder: JSONEncoder = JSONEncoder(),
        file: String = #file, _ function: String = #function, line: Int = #line, log: SCLog? = nil
    ) -> Data? {
        do {
            return try encoder.encode(self)
        } catch {
            (log ?? jsonLogger).error("Encoding \(Self.self) to json failed. Error: \(error)", file, function, line: line)
            return nil
        }
    }
}

extension Decodable {
    /// Initialize value from json using specified decoder.
    /// Log failure to SwiftConvenience.Log
    public init?(
        json: Data, decoder: JSONDecoder = JSONDecoder(),
        file: String = #file, _ function: String = #function, line: Int = #line, log: SCLog? = nil
    ) {
        do {
            self = try decoder.decode(Self.self, from: json)
        } catch {
            (log ?? jsonLogger).error("Decoding \(Self.self) from json failed. Error: \(error)", file, function, line: line)
            return nil
        }
    }
}

private let jsonLogger = SCLogger.internalLog(.codable(.json))


extension Encodable {
    /// Encode value to plist using specified encoder.
    /// Log failure to SwiftConvenience.Log
    public func plist(
        encoder: PropertyListEncoder = PropertyListEncoder(),
        file: String = #file, _ function: String = #function, line: Int = #line, log: SCLog? = nil
    ) -> Data? {
        do {
            return try encoder.encode(self)
        } catch {
            (log ?? plistLogger).error("Encoding \(Self.self) to plist failed. Error: \(error)", file, function, line: line)
            return nil
        }
    }
    
    /// Encode value to plist using specified plist format.
    /// Log failure to SwiftConvenience.Log
    public func plist(
        format: PropertyListSerialization.PropertyListFormat,
        file: String = #file, _ function: String = #function, line: Int = #line, log: SCLog? = nil
    ) -> Data? {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = format
        return plist(encoder: encoder, file: file, function, line: line, log: log)
    }
}

extension Decodable {
    /// Initialize value from plist using specified decoder.
    /// Log failure to SwiftConvenience.Log
    public init?(
        plist: Data, decoder: PropertyListDecoder = PropertyListDecoder(),
        file: String = #file, _ function: String = #function, line: Int = #line, log: SCLog? = nil
    ) {
        do {
            self = try decoder.decode(Self.self, from: plist)
        } catch {
            (log ?? plistLogger).error("Decoding \(Self.self) from plist failed. Error: \(error)", file, function, line: line)
            return nil
        }
    }
}

private let plistLogger = SCLogger.internalLog(.codable(.plist))
