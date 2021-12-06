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


// MARK: - NSError predefined domains

extension NSError {
    public convenience init(posix code: Int32) {
        self.init(domain: NSPOSIXErrorDomain, code: Int(code))
    }
    
    public convenience init(osStatus code: OSStatus) {
        self.init(domain: NSOSStatusErrorDomain, code: Int(code))
    }
    
    public convenience init(mach code: kern_return_t) {
        self.init(domain: NSMachErrorDomain, code: Int(code))
    }
}


// MARK: - NSError Builder

extension NSError {
    public convenience init<Code: BinaryInteger>(domain: String, code: Code) {
        self.init(
            domain: domain,
            code: Int(code),
            userInfo: nil
        )
    }
    
    public func underlyingError(_ error: Error?) -> NSError {
        guard let error = error else { return self }
        
        var userInfo = self.userInfo
        if userInfo[NSUnderlyingErrorKey] != nil, #available(macOS 11.3, iOS 14.5, tvOS 14.5, watchOS 7.4, *) {
            var errors = userInfo[NSMultipleUnderlyingErrorsKey] as? [Error] ?? []
            errors.append(error)
            userInfo[NSMultipleUnderlyingErrorsKey] = errors
        } else {
            userInfo[NSUnderlyingErrorKey] = error
        }
        
        return self.userInfo(userInfo)
    }
    
    public func debugDescription(_ debugDescription: String?) -> NSError {
        guard let debugDescription = debugDescription else { return self }
        
        var userInfo = self.userInfo
        userInfo[NSDebugDescriptionErrorKey] = debugDescription
        
        return self.userInfo(userInfo)
    }
    
    public func userInfo(_ value: Any, for key: String) -> NSError {
        var userInfo = self.userInfo
        userInfo[key] = value
        
        return self.userInfo(userInfo)
    }
    
    public func userInfo(_ userInfo: [String: Any]) -> NSError {
        NSError(domain: domain, code: code, userInfo: userInfo)
    }
}


// MARK: - NSError Try

extension NSError {
    public static var osstatus: TryBuilder<OSStatusTryTag> { .init() }
    public static var posix: TryBuilder<POSIXTryTag> { .init() }
    
    
    public struct OSStatusTryTag {}
    public struct POSIXTryTag {}
    
    public struct TryBuilder<Tag> {
        private var debugDescription: String?
        
        public func debugDescription(_ debugDescription: String) -> Self {
            var copy = self
            copy.debugDescription = debugDescription
            return copy
        }
    }
}

extension NSError.TryBuilder where Tag == NSError.OSStatusTryTag {
    public func `try`<T>(
        body: (UnsafeMutablePointer<T?>, UnsafeMutablePointer<Unmanaged<CFError>?>?) -> OSStatus
    ) throws -> T {
        var result: T?
        var error: Unmanaged<CFError>?
        let status = body(&result, &error)
        
        try osError(status, underlying: error?.takeRetainedValue())?.throw()
        
        return try result.get()
    }
    
    public func `try`<T>(
        body: (UnsafeMutablePointer<T?>, UnsafeMutablePointer<CFError?>?) -> OSStatus
    ) throws -> T {
        var result: T?
        var error: CFError?
        let status = body(&result, &error)
        
        try osError(status, underlying: error)?.throw()
        
        return try result.get()
    }
    
    public func `try`<T>(
        body: (UnsafeMutablePointer<T?>) -> OSStatus
    ) throws -> T {
        var result: T?
        let status = body(&result)
        
        try osError(status)?.throw()
        
        return try result.get()
    }
    
    public func `try`(
        body: () -> OSStatus
    ) throws {
        let status = body()
        try osError(status)?.throw()
    }
    
    public func `try`(
        body: (UnsafeMutablePointer<Unmanaged<CFError>?>?) -> OSStatus
    ) throws {
        var error: Unmanaged<CFError>?
        let status = body(&error)
        
        try osError(status, underlying: error?.takeRetainedValue())?.throw()
    }
    
    public func `try`(
        body: (UnsafeMutablePointer<CFError?>?) -> OSStatus
    ) throws {
        var error: CFError?
        let status = body(&error)
        
        try osError(status, underlying: error)?.throw()
    }
    
    private func osError(_ status: OSStatus, underlying: Error? = nil) -> NSError? {
        guard status != noErr else { return nil }
        return NSError(osStatus: status)
            .underlyingError(underlying)
            .debugDescription(debugDescription)
    }
}

extension NSError.TryBuilder where Tag == NSError.POSIXTryTag {
    public func `try`(_ success: Bool) throws {
        if !success {
            throw posixError()
        }
    }
    
    public func `try`<T>(body: () -> T?) throws -> T {
        if let instance = body() {
            return instance
        } else {
            throw posixError()
        }
    }
    
    private func posixError() -> NSError {
        NSError(posix: errno)
            .debugDescription(debugDescription)
    }
}
