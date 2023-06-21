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

/// Custom Error key which value is object related to the failure.
public let SCRelatedObjectErrorKey: String = "SCRelatedObjectErrorKey"

/// Custom Error key which value is name of some entity the error is about.
public let SCNameErrorKey: String = "SCNameErrorKey"

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
    
    public func appendingUnderlyingError(_ error: Error) -> NSError {
        withUserInfo(error, for: NSUnderlyingErrorKey)
    }
    
    /// Build new error with specified (or replaced) `userInfo` value for `NSDebugDescriptionErrorKey`
    public func withDebugDescription(_ debugDescription: String) -> NSError {
        withUserInfo(debugDescription, for: NSDebugDescriptionErrorKey)
    }
    
    /// Build new error with specified (or replaced) `userInfo` value for given key
    public func withUserInfo(_ value: Any, for key: String) -> NSError {
        withUserInfo([key: value])
    }
    
    /// Build new error with `userInfo`, merged with given `userInfo`
    /// If key in new `userInfo` already exists, the value is replaced
    /// If key exists and is `NSUnderlyingErrorKey` or `NSMultipleUnderlyingErrorsKey`, the error(s) is appended
    public func withUserInfo(_ userInfo: [String: Any]) -> NSError {
        NSError(domain: domain, code: code, userInfo: Self.mergeUserInfo(existing: self.userInfo, new: userInfo))
    }
    
    private static func mergeUserInfo(existing: [String: Any], new: [String: Any]) -> [String: Any] {
        var merged = existing
        new.forEach {
            switch $0.key {
            case NSUnderlyingErrorKey:
                if merged[NSUnderlyingErrorKey] == nil {
                    merged[NSUnderlyingErrorKey] = $0.value
                } else {
                    let errors = merged[Self.multipleUnderlyingErrorsKey] as? [Any] ?? []
                    merged[Self.multipleUnderlyingErrorsKey] = errors.appending($0.value)
                }
            case Self.multipleUnderlyingErrorsKey:
                guard let newErrors = $0.value as? [Error] else {
                    assertionFailure("Value for Error userInfo key \($0.key) MUST be of type [Error]")
                    return
                }
                let errors = merged[$0.key] as? [Any] ?? []
                merged[$0.key] = errors + newErrors
            default:
                merged[$0.key] = $0.value
            }
        }
        return merged
    }
    
    public static let multipleUnderlyingErrorsKey: String = {
        if #available(macOS 11.3, iOS 14.5, tvOS 14.5, watchOS 7.4, *) {
            return NSMultipleUnderlyingErrorsKey
        } else {
            return "NSMultipleUnderlyingErrorsKey"
        }
    }()
}

// MARK: - NSError Try

extension NSError {
    public static var osstatus: TryBuilder<OSStatusTryTag> { .init() }
    public static var posix: TryBuilder<POSIXTryTag> { .init() }
    public static var mach: TryBuilder<MachTryTag> { .init() }
    
    public struct OSStatusTryTag {}
    public struct POSIXTryTag {}
    public struct MachTryTag {}
    
    public struct TryBuilder<Tag> {
        private var userInfo: [String: Any] = [:]
    }
}

extension NSError.TryBuilder {
    public func userInfo(_ value: Any, for key: String) -> Self {
        var copy = self
        copy.userInfo[key] = value
        return copy
    }
    
    public func debugDescription(_ debugDescription: String) -> Self {
        userInfo(debugDescription, for: NSDebugDescriptionErrorKey)
    }
    
    public func named(_ name: String) -> Self {
        userInfo(name, for: SCNameErrorKey)
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
    
    public func `try`<T>(
        body: (UnsafeMutablePointer<Unmanaged<CFError>?>?) -> T?
    ) throws -> T {
        var error: Unmanaged<CFError>?
        let result = body(&error)
        
        try osError(error?.takeRetainedValue())?.throw()
        
        return try result.get()
    }
    
    public func `try`<T>(
        body: (UnsafeMutablePointer<CFError?>?) -> T?
    ) throws -> T {
        var error: CFError?
        let result = body(&error)
        
        try osError(error)?.throw()
        
        return try result.get()
    }
    
    private func osError(_ status: OSStatus, underlying: Error? = nil) -> NSError? {
        guard status != noErr else { return nil }
        return osError(underlying ?? NSError(osStatus: status))
    }
    
    private func osError(_ error: Error?) -> NSError? {
        (error as NSError?)?.withUserInfo(userInfo)
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
            .withUserInfo(userInfo)
    }
}

extension NSError.TryBuilder where Tag == NSError.MachTryTag {
    public func `try`<T>(
        body: (UnsafeMutablePointer<T>) -> kern_return_t
    ) throws -> T {
        let result = UnsafeMutablePointer<T>.allocate(capacity: 1)
        defer { result.deallocate() }
        
        try machError(body(result))?.throw()
        
        return result.pointee
    }
    
    public func `try`(body: () -> kern_return_t) throws {
        try machError(body())?.throw()
    }
    
    private func machError(_ status: kern_return_t) -> NSError? {
        guard status != KERN_SUCCESS else { return nil }
        return NSError(mach: status)
            .withUserInfo(userInfo)
    }
}
