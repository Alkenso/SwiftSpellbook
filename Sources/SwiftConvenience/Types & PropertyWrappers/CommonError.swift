//  MIT License
//
//  Copyright (c) 2021 Alkenso (Vladimir Vashurkin)
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


/// Type representing error for common situations.
public struct CommonError: Error {
    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        self.userInfo = userInfo
    }
    
    public let code: Code
    public let userInfo: [String: Any]
}

extension CommonError {
    public enum Code: Int {
        case fatal
        case unexpected
        case unwrapNil
        case invalidArgument
        case cast
        case notFound
    }
}

extension CommonError: CustomNSError {
    /// CommonError's domain can be customized
    public static var errorDomain = "CommonErrorDomain"
    
    public var errorCode: Int { Int(code.rawValue) }
    public var errorUserInfo: [String : Any] { userInfo }
}

extension CommonError {
    public init(_ code: Code, _ description: String? = nil) {
        var userInfo: [String: Any] = [:]
        if let description = description {
            userInfo[NSDebugDescriptionErrorKey] = description
        }
        self = .init(code, userInfo: userInfo)
    }
    
    public static func fatal(_ description: String) -> Self {
        .init(.fatal, description)
    }
    
    public static func unexpected(_ description: String) -> Self {
        .init(.unexpected, description)
    }
    
    public static func unwrapNil(_ name: String, description: Any? = nil) -> Self {
        let additional = description.flatMap { ". \($0)" } ?? ""
        return .init(.unwrapNil, "Unexpected nil when unwrapping \(name)" + additional)
    }
    
    public static func invalidArgument(arg: String, invalidValue: Any?, description: Any? = nil) -> Self {
        let value = invalidValue.flatMap { "\($0)" } ?? "nil"
        let additional = description.flatMap { ". \($0)" } ?? ""
        return .init(.invalidArgument, "Invalid value \(value) for argument \(arg)" + additional)
    }
    
    public static func cast<From, To>(_ from: From, to: To.Type, description: Any? = nil) -> Self {
        let additional = description.flatMap { ". \($0)" } ?? ""
        return .init(.unwrapNil, "Failed to cast \(from) to \(to)" + additional)
    }
    
    public static func notFound(what: String, value: Any? = nil, where: Any? = nil, description: Any? = nil) -> Self {
        let valueString = value.flatMap { " = \($0)" } ?? ""
        let whereString = `where`.flatMap { " in \($0)" } ?? ""
        let additional = description.flatMap { ". \($0)" } ?? ""
        return .init(.notFound, "\(what)\(valueString) not found \(whereString)" + additional)
    }
}


// MARK: Optional extension

extension Optional {
    /// Unwraps Error that is expected to be not nil, but syntactically is optional.
    /// Often happens when bridge ObjC <-> Swift API.
    public func get() throws -> Wrapped {
        if let value = self {
            return value
        } else {
            throw CommonError.unwrapNil("Nil found when unwrapping \(Self.self)")
        }
    }
    
    public func get(underlyingError: Error) throws -> Wrapped {
        if let value = self {
            return value
        } else {
            throw CommonError.unwrapNil("Nil found when unwrapping \(Self.self). Underlying error: \(underlyingError)")
        }
    }
    
    public func get(named name: String) throws -> Wrapped {
        if let value = self {
            return value
        } else {
            throw CommonError.unwrapNil("Nil found when unwrapping '\(name)' of type \(Self.self)")
        }
    }
}

extension Optional where Wrapped: Error {
    /// Unwraps Error that is expected to be not nil, but syntactically is optional.
    /// Often happens when bridge ObjC <-> Swift API.
        public var unwrapSafely: Error {
            self ?? CommonError.unexpected("Unexpected nil error.")
        }
}
