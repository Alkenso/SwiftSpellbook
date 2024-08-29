//  MIT License
//
//  Copyright (c) 2024 Alkenso (Vladimir Vashurkin)
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

private let log = SpellbookLogger.internal(category: "CustomErrorUpdating")

public protocol CustomErrorUpdating where Self: Error {
    var userInfo: [String: Any] { get }
    func replacingUserInfo(_ userInfo: [String: Any]) -> Self
}

extension CustomErrorUpdating {
    /// Build new error appending underlying error.
    public func appendingUnderlyingError(_ error: Error) -> Self {
        updatingUserInfo(error, for: NSUnderlyingErrorKey)
    }
    
    /// Build new error with specified (or replaced) `userInfo` value for `NSDebugDescriptionErrorKey`.
    public func updatingDebugDescription(_ debugDescription: String) -> Self {
        updatingUserInfo(debugDescription, for: NSDebugDescriptionErrorKey)
    }
    
    /// Build new error with specified (or replaced) `userInfo` value for given key.
    public func updatingUserInfo(_ value: Any, for key: String) -> Self {
        updatingUserInfo([key: value])
    }
    
    /// Build new error with `userInfo`, merged with given `userInfo`.
    /// If key in new `userInfo` already exists, the value is replaced.
    /// If key exists and is `NSUnderlyingErrorKey` or `NSMultipleUnderlyingErrorsKey`, the error(s) is appended.
    public func updatingUserInfo(_ userInfo: [String: Any]) -> Self {
        let mergedUserInfo = Self.mergeUserInfo(existing: self.userInfo, new: userInfo)
        return replacingUserInfo(mergedUserInfo)
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
                    log.error("Value for Error userInfo key \($0.key) MUST be of type [Error]", assert: true)
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
    
    public static var multipleUnderlyingErrorsKey: String {
        if #available(macOS 11.3, iOS 14.5, tvOS 14.5, watchOS 7.4, *) {
            return NSMultipleUnderlyingErrorsKey
        } else {
            return "NSMultipleUnderlyingErrorsKey"
        }
    }
}
