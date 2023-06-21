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

public enum DictionaryCodingKey {
    case key(AnyHashable)
    case index(Int)
}

extension DictionaryCodingKey: CodingKey {
    public init(stringValue: String) {
        self = .key(stringValue)
    }
    
    public var stringValue: String {
        switch self {
        case .key(let key):
            return "\(key)"
        case .index(let index):
            return "\(index)"
        }
    }
    
    public init(intValue: Int) {
        self = .index(intValue)
    }
    
    public var intValue: Int? {
        if case .index(let index) = self {
            return index
        } else {
            return nil
        }
    }
}

extension DictionaryCodingKey: ExpressibleByStringLiteral {
    public init(stringLiteral value: StringLiteralType) {
        self.init(stringValue: value)
    }
}

extension DictionaryCodingKey: CustomStringConvertible {
    public var description: String {
        switch self {
        case .key(let key):
            return "key(\(key))"
        case .index(let index):
            return "index(\(index))"
        }
    }
}

extension DictionaryCodingKey {
    internal static func parse(dotPath: String) -> [DictionaryCodingKey] {
        guard !dotPath.isEmpty else { return [] }
        return dotPath.components(separatedBy: ".").map {
            if $0 == "[*]" {
                return .index(.max)
            } else if $0.hasPrefix("["), $0.hasSuffix("]"), let index = Int($0.dropFirst().dropLast()) {
                return .index(index)
            } else {
                return .key($0)
            }
        }
    }
}

public struct DictionaryCodingError: Error {
    public var code: Code
    public var codingPath: [DictionaryCodingKey]
    public var description: String
    public var underlyingError: Error?
    public var context: String?
    public var relatedObject: Any?
    
    public init(
        code: Code, codingPath: [DictionaryCodingKey],
        description: String, underlyingError: Error? = nil,
        context: String? = nil, relatedObject: Any? = nil
    ) {
        self.code = code
        self.codingPath = codingPath
        self.description = description
        self.underlyingError = underlyingError
        self.context = context
        self.relatedObject = relatedObject
    }
}

extension DictionaryCodingError {
    public enum Code: Int {
        case invalidArgument
        case keyNotFound
        case typeMismatch
    }
}

extension DictionaryCodingError: CustomNSError {
    public var errorCode: Int { code.rawValue }
    public static var errorDomain: String { SwiftConvenienceErrorDomain }
    public var errorUserInfo: [String : Any] {
        var userInfo: [String: Any] = [:]
        
        var fullDescription = description
        fullDescription += context.flatMap { ". \($0)" } ?? ""
        fullDescription += "Coding path = \(codingPath)"
        userInfo[NSDebugDescriptionErrorKey] = fullDescription
        
        underlyingError.flatMap { userInfo[NSUnderlyingErrorKey] = $0 }
        relatedObject.flatMap { userInfo[SCRelatedObjectErrorKey] = $0 }
        
        return userInfo
    }
}
