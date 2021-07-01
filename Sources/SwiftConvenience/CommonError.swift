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

public extension CommonError {
    enum Code: Int {
        case fatal
        case unexpected
        case unwrapNil
        case invalidArgument
    }
}

extension CommonError: CustomNSError {
    public static var errorDomain: String { "CommonErrorDomain" }
    public var errorCode: Int { Int(code.rawValue) }
    public var errorUserInfo: [String : Any] { userInfo }
}

public extension CommonError {
    init(_ code: Code, _ description: String? = nil) {
        var userInfo: [String: Any] = [:]
        if let description = description {
            userInfo[NSDebugDescriptionErrorKey] = description
        }
        self = .init(code, userInfo: userInfo)
    }
    
    static func fatal(_ description: String) -> Self {
        .init(.fatal, description)
    }
    
    static func unexpected(_ description: String) -> Self {
        .init(.unexpected, description)
    }
    
    static func unwrapNil(_ name: String) -> Self {
        .init(.unwrapNil, "Unexpected nil when unwrapping \(name)")
    }
    
    static func invalidArgument(arg: String, invalidValue: Any) -> Self {
        .init(.invalidArgument, "Invalid value \(invalidValue) for argument \(arg)")
    }
    
}


// MARK: Optional extension

public extension Optional where Wrapped == Error {
    /// Unwraps Error that is expected to be not nil, but syntactically is optional.
    /// Often happens when bridge ObjC <-> Swift API.
    func unwrapSafely(unexpected: Error? = nil) -> Error {
        self ?? unexpected ?? CommonError.unexpected("Unexpected nil error.")
    }
}
