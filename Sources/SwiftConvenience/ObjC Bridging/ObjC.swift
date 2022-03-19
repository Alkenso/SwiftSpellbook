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
@_implementationOnly import SwiftConvenienceObjC

extension NSException {
    public static func catching<R>(_ body: () -> R) -> NSExceptionResult<R> {
        var result: NSExceptionResult<R>!
        if let exception = SwiftConvenienceObjC.nsException_catching({
            let value = body()
            result = .success(value)
        }) {
            result = .exception(exception)
        }
        return result
    }
}


extension NSXPCConnection {
    public var auditToken: audit_token_t {
        SwiftConvenienceObjC.nsxpcConnection_auditToken(self)
    }
}

public enum NSExceptionResult<Success> {
    case success(Success)
    case exception(NSException)
}

extension NSExceptionResult {
    public var success: Success? {
        if case let .success(value) = self {
            return value
        } else {
            return nil
        }
    }
    
    public var exception: NSException? {
        if case let .exception(value) = self {
            return value
        } else {
            return nil
        }
    }
    
    public func mapToResult<Failure: Error>(exceptionTransform: (NSException) -> Failure) -> Result<Success, Failure> {
        switch self {
        case .success(let success):
            return .success(success)
        case .exception(let exception):
            return .failure(exceptionTransform(exception))
        }
    }
}
