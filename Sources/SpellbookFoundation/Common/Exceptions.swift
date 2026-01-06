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

@_implementationOnly import _SpellbookFoundationObjC

import Foundation

/// Error-like wrapper around Objective-C `NSException` to make it Swift.Error compatible.
public struct NSExceptionError: Error, @unchecked Sendable {
    public var exception: NSException
    public init(exception: NSException) {
        self.exception = exception
    }
}

extension NSExceptionError: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String { exception.description }
    public var debugDescription: String { exception.debugDescription }
}

extension NSException: NonSwiftException {
    public static func evaluate(_ body: () -> Void) -> NSException? {
        SpellbookObjC.nsException_catching(body)
    }
    
    public static func create(with nonSwiftError: NSException) -> NSExceptionError {
        NSExceptionError(exception: nonSwiftError)
    }
}

/// Error-like wrapper around C++ `std::exception` to make it Swift.Error compatible.
public struct CppException: Error {
    public var what: String
    
    public init(what: String) {
        self.what = what
    }
    
    public func raise() -> Never {
        SpellbookObjC.throwCppRuntineErrorException(what)
    }
}

extension CppException: NonSwiftException {
    public static func evaluate(_ body: () -> Void) -> String? {
        SpellbookObjC.cppException_catching(body)
    }
    
    public static func create(with nonSwiftError: String) -> Self {
        CppException(what: nonSwiftError)
    }
}

public protocol NonSwiftException {
    associatedtype NonSwiftError
    associatedtype SwiftError: Error
    static func evaluate(_ body: () -> Void) -> NonSwiftError?
    static func create(with nonSwiftError: NonSwiftError) -> SwiftError
}

extension NonSwiftException {
    public static func catching<R>(_ body: () -> R) -> Result<R, SwiftError> {
        var result: Result<R, SwiftError>!
        if let reason = evaluate({
            let value = body()
            result = .success(value)
        }) {
            result = .failure(create(with: reason))
        }
        return result
    }
    
    public static func catchingAll<R>(_ body: () throws -> R) throws -> R {
        try catching { () -> Result<R, Error> in
            do {
                return .success(try body())
            } catch {
                return .failure(error)
            }
        }.get().get()
    }
}

/// Convenient wrapper to catch Swift, Objective-C and C++ exceptions
/// that may be thrown from the `body` closure.
/// - Warning: Use it reasonably, catching code related to
/// Objective-C and C++ exceptions may affect the performance.
public func catchingAny<R>(_ body: () throws -> R) throws -> R {
    try CppException.catchingAll {
        try NSException.catchingAll(body)
    }
}
