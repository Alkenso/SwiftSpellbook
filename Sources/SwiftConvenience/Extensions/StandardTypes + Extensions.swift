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

public extension Data {
    /// Initializes Data with hex string.
    /// - Parameters:
    ///     - hexString: string in form "00FAB1C0". May be prefixed with "0x".
    init?(hexString string: String) {
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
    
    /// Returns data representation as hex string.
    /// - returns: string in form "00FAB1C0".
    var hexString: String {
        map { String(format: "%02x", $0) }.joined()
    }
}


public extension Data {
    /// Initializes Data with binary representation of POD (Plain Old Data) value.
    init<PODType>(pod: PODType) {
        self = Swift.withUnsafeBytes(of: pod) {
            guard let address = $0.baseAddress else { return Data() }
            return Data(bytes: address, count: MemoryLayout<PODType>.size)
        }
    }
    
    /// Converts data to POD (Plain Old Data) value.
    func pod<PODType>(exactly type: PODType.Type) -> PODType? {
        guard MemoryLayout<PODType>.size == count else { return nil }
        return withUnsafeBytes { $0.load(fromByteOffset: 0, as: type) }
    }
    
    /// Converts data to POD (Plain Old Data) value.
    /// If count > PODType size, only 'size' bytes are taken.
    /// If count < PODType size, the data are appended with zeroes to match the size.
    func pod<PODType>(adopting type: PODType.Type) -> PODType {
        var adopted = self
        let advanceSize = MemoryLayout<PODType>.size - adopted.count
        if advanceSize > 0 {
            adopted += Data(count: advanceSize)
        }
        
        return adopted.withUnsafeBytes { $0.load(fromByteOffset: 0, as: type) }
    }
}


// MARK: - URL

public extension URL {
    /// Initialized URL with string that is guaranteed to be valid URL string.
    init(staticString: StaticString) {
        guard let url = Self(string: "\(staticString)") else {
            preconditionFailure("Invalid static URL string: \(staticString)")
        }

        self = url
    }
}

public extension URL {
    enum FileType: CaseIterable {
        case blockSpecial
        case characterSpecial
        case fifo
        case regular
        case directory
        case symbolicLink
    }
    
    /// Determines file type of given URL.
    /// - returns: file type or nil if URL is not a file URL or file can't be stat'ed.
    var fileType: FileType? {
        guard isFileURL else { return nil }
        return stat(self)
            .map(\.st_mode)
            .flatMap(FileType.init)
    }
}

extension URL.FileType {
    init?(_ mode: mode_t) {
        if let fileType = Self.allCases.first(where: { $0.stMode == mode & $0.stMode }) {
            self = fileType
        } else {
            return nil
        }
    }
    
    private var stMode: mode_t {
        switch self {
        case .blockSpecial: return S_IFBLK
        case .characterSpecial: return S_IFCHR
        case .fifo: return S_IFIFO
        case .regular: return S_IFREG
        case .directory: return S_IFDIR
        case .symbolicLink: return S_IFLNK
        }
    }
}


// MARK: - UUID

public extension UUID {
    /// Initialized UUID with string that is guaranteed to be valid UUID string.
    init(staticString: StaticString) {
        guard let value = Self(uuidString: "\(staticString)") else {
            preconditionFailure("Invalid static UUID string: \(staticString)")
        }
        self = value
    }
}


// MARK: - Result

public extension Result {
    /// Returns Success value if Result if .success, nil otherwise.
    var value: Success? { try? get() }
    
    /// Returns Failure value if Result if .failure, nil otherwise.
    var error: Failure? {
        switch self {
        case .success:
            return nil
        case .failure(let error):
            return error
        }
    }
}


// MARK: - Range

public extension Range {
    init(offset: Bound, length: Bound) where Bound: SignedNumeric {
        self.init(uncheckedBounds: (offset, offset + length))
    }
}
