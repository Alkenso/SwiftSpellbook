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
import Darwin


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
            let byteString = hexString[byteStart...byteEnd]
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
        guard isFileURL else { return }
        throw URLError(
            .unsupportedURL,
            userInfo: [NSDebugDescriptionErrorKey: "URL is not a file: \(self)"]
        )
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


// MARK: - UUID

extension UUID {
    /// Initialized UUID with string that is guaranteed to be valid UUID string.
    public init(staticString: StaticString) {
        guard let value = Self(uuidString: "\(staticString)") else {
            preconditionFailure("Invalid static UUID string: \(staticString)")
        }
        self = value
    }
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
            self = .failure(failure.unwrapSafely)
        }
    }
}


// MARK: - Error

extension Error {
    public func `throw`() throws -> Never {
        throw self
    }
}

// MARK: - Range

extension Range {
    public init(offset: Bound, length: Bound) where Bound: SignedNumeric {
        self.init(uncheckedBounds: (offset, offset + length))
    }
}
