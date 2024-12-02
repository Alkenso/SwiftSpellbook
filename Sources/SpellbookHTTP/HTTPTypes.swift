//  MIT License
//
//  Copyright (c) 2024 Alkenso (Vladimir Vashurkin)
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

import SpellbookFoundation

import Foundation

public struct HTTPMethod: RawRepresentable, Hashable {
    public var rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
}

extension HTTPMethod {
    public static let get = Self(rawValue: "GET")
    public static let post = Self(rawValue: "POST")
    public static let patch = Self(rawValue: "PATCH")
    public static let delete = Self(rawValue: "DELETE")
    public static let put = Self(rawValue: "PUT")
    public static let options = Self(rawValue: "OPTIONS")
    public static let head = Self(rawValue: "HEAD")
    public static let trace = Self(rawValue: "TRACE")
    public static let connect = Self(rawValue: "CONNECT")
}

public struct HTTPQueryItem: RawRepresentable, Hashable, ExpressibleByStringLiteral {
    public var rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init(stringLiteral value: StringLiteralType) { self.rawValue = value }
}

public struct HTTPHeader: RawRepresentable, Hashable {
    public var rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
}


extension HTTPHeader {
    public static let userAgent = HTTPHeader(rawValue: "user-agent")
    public static let authorization = HTTPHeader(rawValue: "authorization")
}

extension HTTPHeader: ExpressibleByStringLiteral {
    public init(stringLiteral value: StringLiteralType) { self.rawValue = value }
}

public struct HTTPAuthorizationType: RawRepresentable, Hashable {
    public var rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
}

extension HTTPAuthorizationType {
    public func header(_ token: String) -> String {
        "\(rawValue) \(token)"
    }
}

extension HTTPAuthorizationType: ExpressibleByStringLiteral {
    public init(stringLiteral value: StringLiteralType) { self.rawValue = value }
}

extension HTTPAuthorizationType: ExpressibleByStringInterpolation {
    public init(stringInterpolation: DefaultStringInterpolation) { self.rawValue = stringInterpolation.description }
}

extension HTTPAuthorizationType {
    public static let basic = HTTPAuthorizationType(rawValue: "Basic")
    public static let bearer = HTTPAuthorizationType(rawValue: "Bearer")
}


public struct HTTPParameters<Key: RawRepresentable> where Key.RawValue: StringProtocol {
    public var items: [KeyValue<Key, String>] = []
    
    public init() {}
    
    public func value(forKey key: Key) -> String? {
        values(forKey: key).first
    }
    
    public func values(forKey key: Key) -> [String] {
        items.filter { equalKeys($0.key, key) }.map((\.value))
    }
    
    public mutating func set(_ value: String, forKey key: Key) {
        if let existing = items.firstIndex(where: { equalKeys($0.key, key) }) {
            items[existing].value = value
        } else {
            add(value, forKey: key)
        }
    }
    
    public mutating func add(_ value: String, forKey key: Key) {
        items.append(.init(key, value))
    }
    
    public mutating func removeValues(forKey key: Key) {
        items.removeAll { $0.key == key }
    }
    
    private func equalKeys(_ lhs: Key, _ rhs: Key) -> Bool {
        lhs.rawValue.compare(rhs.rawValue, options: .caseInsensitive) == .orderedSame
    }
}

extension HTTPParameters where Key == HTTPHeader {
    public mutating func setAuthorization(_ type: HTTPAuthorizationType, _ token: String) {
        set(type.header(token), forKey: .authorization)
    }
}
