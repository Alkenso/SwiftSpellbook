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
    public func json(encoder: JSONEncoder = JSONEncoder(), file: String = #file, _ function: String = #function, line: Int = #line, context: Any? = nil) -> Data? {
        do {
            return try encoder.encode(self)
        } catch {
            SwiftConvenience.Log.jsonEncodingError?(error, file, function, line, context)
            return nil
        }
    }
}

extension Decodable {
    /// Initialize value from json using specified decoder.
    /// Log failure to SwiftConvenience.Log
    public init?(json: Data, decoder: JSONDecoder = JSONDecoder(), file: String = #file, _ function: String = #function, line: Int = #line, context: Any? = nil) {
        do {
            self = try decoder.decode(Self.self, from: json)
        } catch {
            SwiftConvenience.Log.jsonDecodingError?(error, file, function, line, context)
            return nil
        }
    }
}

extension SwiftConvenience.Log {
    public static var jsonEncodingError: ((_ error: Error, _ file: String, _ function: String, _ line: Int, _ context: Any?) -> Void)? = {
        logFailure?("Encoding \(Self.self) to json failed. Error: \($0)", $1, $2, $3, $4)
    }
    
    public static var jsonDecodingError: ((_ error: Error, _ file: String, _ function: String, _ line: Int, _ context: Any?) -> Void)? = {
        logFailure?("Decoding \(Self.self) from json failed. Error: \($0)", $1, $2, $3, $4)
    }
}


extension Encodable {
    /// Encode value to plist using specified encoder.
    /// Log failure to SwiftConvenience.Log
    public func plist(encoder: PropertyListEncoder = PropertyListEncoder(), file: String = #file, _ function: String = #function, line: Int = #line, context: Any? = nil) -> Data? {
        do {
            return try encoder.encode(self)
        } catch {
            SwiftConvenience.Log.plistEncodingError?(error, file, function, line, context)
            return nil
        }
    }
    
    /// Encode value to plist using specified plist format.
    /// Log failure to SwiftConvenience.Log
    public func plist(format: PropertyListSerialization.PropertyListFormat, file: String = #file, _ function: String = #function, line: Int = #line, context: Any? = nil) -> Data? {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = format
        return plist(encoder: encoder, file: file, function, line: line, context: context)
    }
}

extension Decodable {
    /// Initialize value from plist using specified decoder.
    /// Log failure to SwiftConvenience.Log
    public init?(plist: Data, decoder: PropertyListDecoder = PropertyListDecoder(), file: String = #file, _ function: String = #function, line: Int = #line, context: Any? = nil) {
        do {
            self = try decoder.decode(Self.self, from: plist)
        } catch {
            SwiftConvenience.Log.plistDecodingError?(error, file, function, line, context)
            return nil
        }
    }
}

extension SwiftConvenience.Log {
    public static var plistEncodingError: ((_ error: Error, _ file: String, _ function: String, _ line: Int, _ context: Any?) -> Void)? = {
        logFailure?("Encoding \(Self.self) to plist failed. Error: \($0)", $1, $2, $3, $4)
    }
    
    public static var plistDecodingError: ((_ error: Error, _ file: String, _ function: String, _ line: Int, _ context: Any?) -> Void)? = {
        logFailure?("Decoding \(Self.self) from plist failed. Error: \($0)", $1, $2, $3, $4)
    }
}
