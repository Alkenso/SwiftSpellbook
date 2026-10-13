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
public struct CommonError: Error, Sendable {
    public var code: Code
    public nonisolated(unsafe) var userInfo: [String: Any]
    
    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        self.userInfo = userInfo
    }
}

extension CommonError {
    public enum Code: Int, Sendable {
        case general
        case fatal
        case unexpected
        case unwrapNil
        case invalidArgument
        case cast
        case notFound
        case outOfRange
        case timedOut
    }
}

extension CommonError: CustomNSError {
    /// CommonError's domain can be customized
    public nonisolated(unsafe) static var errorDomain = "CommonErrorDomain"
    
    public var errorCode: Int { Int(code.rawValue) }
    public var errorUserInfo: [String: Any] { userInfo }
}

extension CommonError: _ObjectiveCBridgeableError {
    public init?(_bridgedNSError: NSError) {
        guard _bridgedNSError.domain == Self.errorDomain else { return nil }
        guard let code = Code(rawValue: _bridgedNSError.code) else { return nil }
        self.init(code, userInfo: _bridgedNSError.userInfo)
    }
}

extension CommonError: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        var components = ["Error Domain=\(Self.errorDomain) Code=\(code.description)(\(code.rawValue))"]
        let messageKey = [NSDebugDescriptionErrorKey, NSLocalizedDescriptionKey].first {
            Self.descriptionText(userInfo[$0] as? String) != nil
        }
        if let messageKey, let message = Self.descriptionText(userInfo[messageKey]) {
            components.append(String(reflecting: message))
        }
        let details = userInfo.sorted { $0.key < $1.key }.filter { $0.key != messageKey }.map { key, value in
            let value = (value as? String).map { String(reflecting: $0) } ?? String(describing: value)
            return "\(key)=\(value)"
        }
        if !details.isEmpty {
            components.append("UserInfo={\(details.joined(separator: ", "))}")
        }
        return components.joined(separator: " ")
    }
    
    public var debugDescription: String { description }
}

extension CommonError.Code: CustomStringConvertible {
    public var description: String {
        switch self {
        case .general: return "General"
        case .fatal: return "Fatal"
        case .unexpected: return "Unexpected"
        case .unwrapNil: return "UnwrapNil"
        case .invalidArgument: return "InvalidArgument"
        case .cast: return "Cast"
        case .notFound: return "NotFound"
        case .outOfRange: return "OutOfRange"
        case .timedOut: return "TimedOut"
        }
    }
}

extension CommonError {
    public init(_ code: Code, _ description: String? = nil, localized: String? = nil, reason: Error? = nil) {
        var userInfo: [String: Any] = [:]
        if let description {
            userInfo[NSDebugDescriptionErrorKey] = description
        }
        if let localized {
            userInfo[NSLocalizedDescriptionKey] = localized
        }
        if let reason {
            userInfo[NSUnderlyingErrorKey] = reason
        }
        self = .init(code, userInfo: userInfo)
    }
    
    public init(_ description: String, reason: Error? = nil) {
        self.init(.general, description, reason: reason)
    }
    
    public init(localized: String, debug: String? = nil, reason: Error? = nil) {
        self.init(.general, debug, localized: localized, reason: reason)
    }
    
    public init(_ userInfo: [String: Any]) {
        self.init(.general, userInfo: userInfo)
    }
}

extension CommonError: CustomErrorUpdating {
    public func replacingUserInfo(_ userInfo: [String : Any]) -> CommonError {
        .init(code, userInfo: userInfo)
    }
}

extension CommonError {
    public static func fatal(_ description: String) -> Self {
        .init(.fatal, description)
    }
    
    public static func unexpected(_ description: String) -> Self {
        .init(.unexpected, description)
    }
    
    public static func unwrapNil(_ name: String, description: Any? = nil) -> Self {
        self.init(.unwrapNil, description: description, components: [
            "Unexpected nil when unwrapping '\(name)'"
        ])
    }
    
    public static func invalidArgument(arg: String, invalidValue: Any?, description: Any? = nil) -> Self {
        self.init(.invalidArgument, description: description, components: [
            "Invalid value",
            invalidValue.map { "'\($0)'" } ?? "nil",
            "for argument '\(arg)'",
        ])
    }
    
    public static func cast<From, To>(name: String? = nil, _ from: From, to: To.Type, description: Any? = nil) -> Self {
        self.init(.cast, description: description, components: [
            "Failed to cast",
            descriptionText(name).map { "'\($0)'" },
            "from",
            "type \(type(of: from)) to \(to)"
        ])
    }
    
    public static func notFound(what: String, value: Any? = nil, where: Any? = nil, description: Any? = nil) -> Self {
        self.init(.notFound, description: description, components: [
            what,
            value.map { "'\($0)'" },
            "not found",
            descriptionText(`where`).map { "in \($0)" },
        ])
    }
    
    public static func outOfRange(what: String, value: Any? = nil, where: Any? = nil, limitValue: Any? = nil, description: Any? = nil) -> Self {
        self.init(.outOfRange, description: description, components: [
            what,
            value.map { "'\($0)'" },
            "is out of range",
            descriptionText(`where`).map { "in \($0)" },
            limitValue.map { "(limit: '\($0)')" }
        ])
    }
    
    public static func timedOut(what: String, description: Any? = nil) -> Self {
        self.init(.timedOut, description: description, components: [
            what,
            "timed out",
        ])
    }
    
    private init(_ code: Code, description: Any?, components: [Any?]) {
        let fullDescription = Self.makeDescription(description, components: components)
        self.init(code, fullDescription)
    }
    
    private static func makeDescription(_ description: Any?, components: [Any?]) -> String {
        let componentsText = components.compactMap { descriptionText($0) }.joined(separator: " ")
        return [descriptionText(componentsText), descriptionText(description)].compactMap { $0 }.joined(separator: ". ")
    }
    
    private static func descriptionText(_ value: Any?) -> String? {
        guard let value else { return nil }
        let text = String(describing: value).trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? nil : text
    }
}
