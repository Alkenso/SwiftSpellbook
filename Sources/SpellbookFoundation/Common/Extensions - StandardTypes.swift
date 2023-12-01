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

import Darwin
import Foundation

// MARK: - Data

extension DataProtocol {
    /// Returns data representation as hex string.
    /// - returns: string in form "00fab1c0".
    public var hexString: String {
        map { String(format: "%02x", $0) }.joined()
    }
}

extension Data {
    /// Initializes Data with hex string.
    /// - Parameters:
    ///     - hexString: string in form "00FAB1C0". May be prefixed with "0x".
    public init?(hexString string: String) {
        let hexString = string.dropFirst(string.hasPrefix("0x") ? 2 : 0)
        guard hexString.count.isMultiple(of: 2) else { return nil }
        
        var data = Data(capacity: hexString.count / 2)
        for i in stride(from: 0, to: hexString.count, by: 2) {
            let byteStart = hexString.index(hexString.startIndex, offsetBy: i)
            let byteEnd = hexString.index(after: byteStart)
            let byteString = hexString[byteStart ... byteEnd]
            guard let byte = UInt8(byteString, radix: 16) else { return nil }
            data.append(byte)
        }
        self = data
    }
}

extension Data {
    /// Initializes Data with binary representation of POD (Plain Old Data) value.
    public init<PODType>(pod: PODType) {
        self = Swift.withUnsafeBytes(of: pod) {
            guard let address = $0.baseAddress else { return Data() }
            return Data(bytes: address, count: MemoryLayout<PODType>.size)
        }
    }
    
    /// Converts data to POD (Plain Old Data) value.
    public func pod<PODType>(exactly type: PODType.Type) -> PODType? {
        guard MemoryLayout<PODType>.size == count else { return nil }
        return withUnsafeBytes { $0.load(fromByteOffset: 0, as: type) }
    }
    
    /// Converts data to POD (Plain Old Data) value.
    /// If count > PODType size, only 'size' bytes are taken.
    /// If count < PODType size, the data are appended with zeroes to match the size.
    public func pod<PODType>(adopting type: PODType.Type) -> PODType {
        var adopted = self
        let advanceSize = MemoryLayout<PODType>.size - adopted.count
        if advanceSize > 0 {
            adopted += Data(count: advanceSize)
        }
        
        return adopted.withUnsafeBytes { $0.load(fromByteOffset: 0, as: type) }
    }
}

extension Data {
    /// Returns Data with `count` random bytes.
    ///
    /// Uses `arc4random_buf` under the hood.
    public static func random(_ count: Int) -> Data {
        guard count > 0 else { return Data() }
        
        var data = Data(repeating: 0, count: count)
        data.withUnsafeMutableBytes {
            arc4random_buf($0.baseAddress, $0.count)
        }
        return data
    }
}

extension Data {
    /// Initialize a `Data` with the contents of a `URL` or 
    /// empty Data if URL is a file that does not exist.
    ///
    /// - parameter url: The `URL` to read.
    /// - parameter options: Options for the read operation. Default value is `[]`.
    /// - parameter ifNoFile: Optional `Data` replacement if a file does not exist.
    /// - throws: An error in the Cocoa domain, if `url` cannot be read.
    public init(contentsOf url: URL, options: Data.ReadingOptions = [], ifNoFile replacementContent: Data?) throws {
        do {
            try self.init(contentsOf: url, options: options)
        } catch let error as CocoaError where [.fileNoSuchFile, .fileReadNoSuchFile].contains(error.code) {
            if let replacementContent {
                self = replacementContent
            } else {
                throw error
            }
        }
    }
    
    /// Initialize a `Data` with the contents of a file at path or
    /// empty Data if URL is a file that does not exist.
    ///
    /// - parameter path: File path to read.
    /// - parameter options: Options for the read operation. Default value is `[]`.
    /// - parameter ifNoFile: Optional `Data` replacement if a file does not exist.
    /// - throws: An error in the Cocoa domain, if `url` cannot be read.
    public init(contentsOfFile path: String, options: Data.ReadingOptions = [], ifNoFile replacementContent: Data? = nil) throws {
        try self.init(contentsOf: URL(fileURLWithPath: path), options: options, ifNoFile: replacementContent)
    }
}

// MARK: - URL

extension URL {
    /// Initialized URL with string that is guaranteed to be valid URL string.
    public init(staticString: StaticString) {
        guard let url = Self(string: "\(staticString)") else {
            preconditionFailure("Invalid static URL string: \(staticString)")
        }
        
        self = url
    }
}

extension URL {
    /// Determines file type of given URL.
    /// Does NOT resolve symlinks.
    /// - returns: file type or nil if URL is not a file URL or file can't be stat'ed.
    public func ensureFileURL() throws {
        if !isFileURL {
            throw URLError(
                .unsupportedURL,
                userInfo: [NSDebugDescriptionErrorKey: "URL is not a file: \(self)"]
            )
        }
    }
}

// MARK: - String

extension String {
    public var pathComponents: [String] { (self as NSString).pathComponents }
    public var lastPathComponent: String { (self as NSString).lastPathComponent }
    public func appendingPathComponent(_ str: String) -> String {
        (self as NSString).appendingPathComponent(str)
    }
    
    public var deletingLastPathComponent: String { (self as NSString).deletingLastPathComponent }
    
    public var pathExtension: String { (self as NSString).pathExtension }
    public func appendingPathExtension(_ str: String) -> String {
        let result = (self as NSString).appendingPathExtension(str)
        return result ?? (self + "." + str)
    }
    
    public var deletingPathExtension: String { (self as NSString).deletingPathExtension }
}

extension String {
    /// Creates String from valid UTF-8 data.
    /// The caller if fully responsible for validity of the data passed in.
    public init<UTF8Data: DataProtocol>(validUTF8 data: UTF8Data) {
        self.init(decoding: data, as: UTF8.self)
    }
    
    /// UTF-8 representation of the string.
    public var utf8Data: Data {
        Data(utf8)
    }
}

extension StringProtocol {
    /// Parse string consisted of key-value pairs.
    ///
    /// Example:
    /// ```
    /// - string: "key1=value1,key2=value2"
    /// - call: string.parseKeyValuePairs(keyValue: "=", pairs: ",")
    /// - result: [("key1", "value1"), ("key2", "value2")] as [KeyValue<String, String>]
    /// ```
    ///
    /// Supports duplicated keys.
    ///
    /// - Parameters:
    ///     - keyValue: separator used to split key from value.
    ///     - pairs: separator used to split keyValue pairs.
    ///     - allowSeparatorsInValue: if true, then it is legal for the `value` in pair to contain a separator.
    /// - returns: array of key-value pairs.
    /// - throws: error if string is not valid key-value pairs string or if `keyValue` / `pairsSeparator` is empty.
    public func parseKeyValuePairs(
        keyValue keyValueSeparator: String, 
        pairs pairsSeparator: String,
        allowSeparatorsInValue: Bool = false
    ) throws -> [KeyValue<String, String>] {
        guard !pairsSeparator.isEmpty else {
            throw CommonError.invalidArgument(
                arg: "pairsSeparator", invalidValue: pairsSeparator, description: "empty separator"
            )
        }
        
        let pairs = components(separatedBy: pairsSeparator)
        return try pairs.map {
            try $0.parseKeyValuePair(separator: keyValueSeparator, allowSeparatorsInValue: allowSeparatorsInValue)
        }
    }
    
    /// Parse key-value pair string.
    ///
    /// Example:
    /// ```
    /// - string: "key1=value1"
    /// - call: string.parseKeyValuePair(separatedBy: "=")
    /// - result: ("key1", "value1") as KeyValue<String, String>
    /// ```
    ///
    /// - Parameters:
    ///     - separatedBy: separator used to split key from value.
    ///     - allowSeparatorsInValue: if true, then it is legal for the `value` to contain a separator.
    ///     For example, "key=value=1" will be parsed as "key" + "value=1".
    /// - returns: key-value pair.
    /// - throws: error if string is not valid key-value pair string or if `separator` is empty.
    public func parseKeyValuePair(separator: String, allowSeparatorsInValue: Bool = false) throws -> KeyValue<String, String> {
        guard !separator.isEmpty else {
            throw CommonError.invalidArgument(
                arg: "keyValueSeparator", invalidValue: separator, description: "empty separator"
            )
        }
        
        let keyValue = components(separatedBy: separator)
        guard keyValue.count == 2 || (2 < keyValue.count && allowSeparatorsInValue) else {
            throw CommonError.invalidArgument(
                arg: "key-value pair", invalidValue: self,
                description: "not a key-value pair separated by '\(separator)'"
            )
        }
        
        return KeyValue(keyValue[0], keyValue.dropFirst().joined(separator: separator))
    }
}

// MARK: - UUID

extension UUID {
    /// Initialized UUID with string that is guaranteed to be valid UUID string.
    public init(staticString: StaticString) {
        guard let value = Self(uuidString: "\(staticString)") else {
            preconditionFailure("Invalid static UUID string: \(staticString)")
        }
        self = value
    }
    
    public static let zero = UUID(staticString: "00000000-0000-0000-0000-000000000000")
}

// MARK: - Result

extension Result {
    /// Returns Success value if Result if .success, nil otherwise.
    public var success: Success? { try? get() }
    
    /// Returns Failure value if Result if .failure, nil otherwise.
    public var failure: Failure? {
        switch self {
        case .success:
            return nil
        case .failure(let error):
            return error
        }
    }
}

extension Result where Failure == Error {
    /// Convenient conversion ObjC-API completion result into Result instance.
    /// If prefers success: if success is present, creates Result.success case,
    /// otherwise creates Result.failure with provided failure.
    public init(success: Success?, failure: Failure?) {
        if let success = success {
            self = .success(success)
        } else {
            self = .failure(failure.safelyUnwrapped)
        }
    }
    
    /// Returns a new result, mapping any success value using the given
    /// transformation that may also throw.
    ///
    /// Use this method when you need to transform the value of a `Result`
    /// instance when it represents a success.
    /// The difference from original `map` is `transform` closure may also throw.
    ///
    /// - Parameter transform: A closure that takes the success value of this
    ///   instance.
    /// - Returns: A `Result` instance with the result of evaluating `transform`
    ///   as the new success value if this instance represents a success.
    public func mapT<NewSuccess>(_ transform: (Success) throws -> NewSuccess) -> Result<NewSuccess, Error> {
        Result<NewSuccess, Failure> { try transform(get()) }
    }
}

extension Result where Success == Void {
    /// Create Result object with failure if it present or success otherwise.
    public init(failure: Failure?) {
        if let failure {
            self = .failure(failure)
        } else {
            self = .success(())
        }
    }
}

// MARK: - Error

extension Error {
    public func `throw`() throws -> Never {
        throw self
    }
}

extension Error {
    /// Not all `Error` objects are NSSecureCoding-compilant.
    /// Such incompatible errors cause raising of NSException during encoding or decoding of XPC messages.
    /// To avoid this, the method perform manual type-check and converting incompatible errors
    /// into most close-to-original but compatible form.
    public func xpcCompatible() -> Error {
        let nsError = self as NSError
        guard (try? NSKeyedArchiver.archivedData(withRootObject: nsError, requiringSecureCoding: true)) == nil else {
            return self
        }
        
        let compatibleError = NSError(
            domain: nsError.domain,
            code: nsError.code,
            userInfo: nsError.userInfo.mapValues {
                JSONSerialization.isValidJSONObject($0) ? $0 : String(describing: $0)
            }
        )
        return compatibleError
    }
}

// MARK: - Range

extension Range {
    public init(offset: Bound, length: Bound) where Bound: SignedNumeric {
        self.init(uncheckedBounds: (offset, offset + length))
    }
}

// MARK: - Optional

extension Optional {
    /// Returns the value if present or throws error otherwise
    public func get(name: String? = nil, description: String? = nil, reason: Error? = nil) throws -> Wrapped {
        if let value = self {
            return value
        }
        
        let valueName = name.flatMap { "'\($0)'" } ?? "value"
        var message = "Nil found when unwrapping \(valueName) of type \(Self.self)"
        description.flatMap { message += ". \($0)" }
        
        var userInfo: [String: Any] = [:]
        userInfo[NSDebugDescriptionErrorKey] = message
        userInfo[NSUnderlyingErrorKey] = reason
        throw CommonError(.unwrapNil, userInfo: userInfo)
    }
    
    /// Returns the value if present or throws error otherwise
    public func get(_ error: Error) throws -> Wrapped {
        if let value = self {
            return value
        } else {
            throw error
        }
    }
}

extension Optional where Wrapped: Error {
    /// Unwraps Error that is expected to be not nil, but syntactically is optional.
    /// Often happens when bridge ObjC <-> Swift API.
    public var safelyUnwrapped: Error {
        self ?? CommonError.unexpected("Unexpected nil when unwrapping logically non-nil error.")
    }
}

extension Optional {
    /// Provides convenient way of mutating optional values.
    ///
    /// ```
    /// // Case 1
    /// var value: Int? = nil
    /// value[default: 10] += 1 // value contains `11`
    ///
    /// // Case 2
    /// struct Stru {
    ///     var value: Int?
    /// }
    /// var dict: [String: Stru] = ["key": Stru()]
    /// dict["key"]?.value[default: 10] += 1 // ["key": Stru(value: 11)]
    /// ```
    public subscript(default defaultValue: @autoclosure () -> Wrapped) -> Wrapped {
        get {
            if let value = self {
                return value
            } else {
                return defaultValue()
            }
        }
        set {
            self = newValue
        }
    }
}

// MARK: - TimeInterval & Date

extension TimeInterval {
    /// Creates `TimeInverval` from `timespec` structure.
    public init(ts: timespec) {
        self = TimeInterval(ts.tv_sec) + (TimeInterval(ts.tv_nsec) / TimeInterval(NSEC_PER_SEC))
    }
}

extension Date {
    /// Creates `TimeInverval` from `timespec` structure.
    /// - Note: Expected accuracy of resulting `Date` is ~100 nanoseconds.
    public init(ts: timespec) {
        self.init(timeIntervalSince1970: TimeInterval(ts: ts))
    }
}

extension Date {
    /// Indicates whether **this** Date is in the past related to **now**.
    public var inPast: Bool {
        self < Date()
    }
    
    /// Indicates whether **this** Date is in the future related to **now**.
    public var inFuture: Bool {
        Date() < self
    }
}

extension Calendar {
    public static let iso8601UTC: Calendar = {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()
    
    /// The last moment of the given date. 1ms less than next day start.
    public func endOfDay(for date: Date) -> Date {
        startOfDay(for: date).addingTimeInterval(24 * 60 * 60 - 0.001)
    }
}
