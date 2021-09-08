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


public struct BinaryWriter {
    private let _output: BinaryWriterOutput
    
    public var userInfo: [String: Any] = [:]
    public private(set) var offset: Int = 0
    
    
    public init(_ output: BinaryWriterOutput) {
        _output = output
    }
    
    public func size() throws -> Int {
        try _output.size()
    }
    
    public mutating func append(_ buffer: UnsafeRawBufferPointer) throws {
        try write(buffer, at: offset)
        offset += buffer.count
    }
    
    public func write(_ buffer: UnsafeRawBufferPointer, at offset: Int) throws {
        try _output.writeBytes(from: buffer.bindMemory(to: UInt8.self), at: offset)
    }
    
    public mutating func seek(_ offset: Int) throws {
        self.offset = offset
    }
}

public extension BinaryWriter {
    func write(_ data: Data, at offset: Int) throws {
        try data.withUnsafeBytes {
            try write($0, at: offset)
        }
    }
    
    func writeTrivial<T>(_ value: T, at offset: Int) throws {
        let data = Data(pod: value)
        try write(data, at: offset)
    }
    
    func writeUInt8(_ value: UInt8, at offset: Int) throws {
        try writeTrivial(value, at: offset)
    }
    
    func writeUInt16(_ value: UInt16, at offset: Int) throws {
        try writeTrivial(value, at: offset)
    }
    
    func writeUInt32(_ value: UInt32, at offset: Int) throws {
        try writeTrivial(value, at: offset)
    }
    
    func writeUInt64(_ value: UInt64, at offset: Int) throws {
        try writeTrivial(value, at: offset)
    }
    
    func writeDefaultUInt(_ value: UInt, at offset: Int) throws {
        try writeTrivial(value, at: offset)
    }
    
    func writeInt8(_ value: Int8, at offset: Int) throws {
        try writeTrivial(value, at: offset)
    }
    
    func writeInt16(_ value: Int16, at offset: Int) throws {
        try writeTrivial(value, at: offset)
    }
    
    func writeInt32(_ value: Int32, at offset: Int) throws {
        try writeTrivial(value, at: offset)
    }
    
    func writeInt64(_ value: Int64, at offset: Int) throws {
        try writeTrivial(value, at: offset)
    }
    
    func writeDefaultInt(_ value: Int, at offset: Int) throws {
        try writeTrivial(value, at: offset)
    }
    
    func writeZeroes(in range: Range<Int>) throws {
        let data = Data(repeating: 0, count: range.count)
        try write(data, at: range.lowerBound)
    }
}

public extension BinaryWriter {
    mutating func append(_ data: Data) throws {
        try data.withUnsafeBytes {
            try append($0)
        }
    }
    
    mutating func appendTrivial<T>(_ value: T) throws {
        let data = Data(pod: value)
        try append(data)
    }
    
    mutating func appendUInt8(_ value: UInt8) throws {
        try appendTrivial(value)
    }
    
    mutating func appendUInt8(_ value: UInt16) throws {
        try appendTrivial(value)
    }
    
    mutating func appendUInt32(_ value: UInt32) throws {
        try appendTrivial(value)
    }
    
    mutating func appendUInt64(_ value: UInt64) throws {
        try appendTrivial(value)
    }
    
    mutating func appendDefaultUInt(_ value: UInt) throws {
        try appendTrivial(value)
    }
    
    mutating func appendInt8(_ value: Int8) throws {
        try appendTrivial(value)
    }
    
    mutating func appendInt16(_ value: Int16) throws {
        try appendTrivial(value)
    }
    
    mutating func appendInt32(_ value: Int32) throws {
        try appendTrivial(value)
    }
    
    mutating func appendInt64(_ value: Int64) throws {
        try appendTrivial(value)
    }
    
    mutating func appendDefaultInt(_ value: Int) throws {
        try appendTrivial(value)
    }
    
    mutating func appendZeroes(_ count: Int) throws {
        let data = Data(repeating: 0, count: count)
        try append(data)
    }
}

public extension BinaryWriter {
    mutating func reset() {
        try? seek(0)
    }
    
    func resetted() -> Self {
        var copy = self
        copy.reset()
        return copy
    }
}

public enum BinaryWriterError: Error {
    case outOfRange
}
