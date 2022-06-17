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
