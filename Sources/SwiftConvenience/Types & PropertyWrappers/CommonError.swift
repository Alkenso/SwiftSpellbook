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
    
    public var code: Code
    public var userInfo: [String: Any]
}

extension CommonError {
    public enum Code: Int {
        case general
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
    
    public init(_ description: String) {
        self.init(.general, description)
    }
    
    public init(userInfo: [String: Any]) {
        self.init(.general, userInfo: userInfo)
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
    
    public static func cast<From, To>(name: String? = nil, _ from: From, to: To.Type, description: Any? = nil) -> Self {
        var fullDescription = "Failed to cast "
        if let what = name {
            fullDescription += "'\(what)' of"
        } else {
            fullDescription += "from"
        }
        fullDescription += " type \(type(of: from)) to \(to)"
        if let description = description {
            fullDescription += ". \(description)"
        }
        
        return .init(.cast, fullDescription)
    }
    
    public static func notFound(what: String, value: Any? = nil, where: Any? = nil, description: Any? = nil) -> Self {
        let valueString = value.flatMap { " = \($0)" } ?? ""
        let whereString = `where`.flatMap { " in \($0)" } ?? ""
        let additional = description.flatMap { ". \($0)" } ?? ""
        return .init(.notFound, "\(what)\(valueString) not found \(whereString)" + additional)
    }
}
