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


extension NSError {
    public convenience init(domain: String, code: Int, underlyingError: Error? = nil, debugDescription: String? = nil) {
        var userInfo: [String: Any] = [:]
        underlyingError.flatMap { userInfo[NSUnderlyingErrorKey] = $0 }
        debugDescription.flatMap { userInfo[NSDebugDescriptionErrorKey] = $0 }
        
        self.init(
            domain: domain,
            code: code,
            userInfo: !userInfo.isEmpty ? userInfo : nil
        )
    }
    
    
    //  MARK: OSStatus
    
    public convenience init?(os: OSStatus, underlyingError: CFError? = nil, debugDescription: String? = nil) {
        guard os != noErr else { return nil }
        self.init(domain: NSOSStatusErrorDomain, code: Int(os), underlyingError: underlyingError, debugDescription: debugDescription)
    }
    
    public static func osTry<T>(
        debug debugDescription: String? = nil,
        _ type: T.Type,
        body: (UnsafeMutablePointer<T?>, UnsafeMutablePointer<Unmanaged<CFError>?>) -> OSStatus
    ) throws -> T {
        var result: T?
        var error: Unmanaged<CFError>?
        let status = body(&result, &error)
        if let nsError = NSError(os: status, underlyingError: error?.takeRetainedValue(), debugDescription: debugDescription) {
            throw nsError
        } else {
            return try result.get()
        }
    }
    
    public static func osTry<T>(
        debug debugDescription: String? = nil,
        _ type: T.Type,
        body: (UnsafeMutablePointer<T?>) -> OSStatus
    ) throws -> T {
        try osTry(debug: debugDescription, T.self) { resultPtr, _ in body(resultPtr) }
    }
    
    public static func osTry(
        debug debugDescription: String? = nil,
        body: () -> OSStatus
    ) throws {
        do {
            try osTry(debug: debugDescription, Void.self) { _, _ in body() }
        } catch let error as CommonError where error.code == .unwrapNil {
            //  do nothing
        }
    }
    
    public static func osTry(
        debug debugDescription: String? = nil,
        body: (UnsafeMutablePointer<Unmanaged<CFError>?>) -> OSStatus
    ) throws {
        do {
            try osTry(debug: debugDescription, Void.self) { _, errorPtr in body(errorPtr) }
        } catch let error as CommonError where error.code == .unwrapNil {
            //  do nothing
        }
    }
    
    
    //  MARK: POSIX
    
    public convenience init?(posixSuccess: Bool, debugDescription: String? = nil) {
        guard !posixSuccess && errno != 0 else { return nil }
        self.init(domain: NSPOSIXErrorDomain, code: Int(errno), debugDescription: debugDescription)
    }
    
    public static func posixTry(
        debug debugDescription: String? = nil,
        _ success: Bool
    ) throws {
        if let nsError = NSError(posixSuccess: success, debugDescription: debugDescription) {
            throw nsError
        }
    }
}
