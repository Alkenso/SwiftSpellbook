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


public struct BinaryReader {
    public private(set) var offset: Int = 0
    
    public var userInfo: [String: Any] = [:]
    
    
    public init(_ source: BinaryReaderInput) {
        _input = source
    }
    
    public func size() throws -> Int {
        try _input.size()
    }
    
    public func peek(to buffer: UnsafeMutableRawBufferPointer, offset: Int) throws {
        let requiredInputSize = offset + buffer.count
        try ensureSize(requiredInputSize)

        try _input.readBytes(to: buffer.bindMemory(to: UInt8.self), offset: offset)
    }
    
    public mutating func seek(_ offset: Int) throws {
        try ensureSize(offset)
        
        self.offset = offset
    }
    
    public mutating func reset() {
        offset = 0
    }
    
    
    // MARK: Private
    private let _input: BinaryReaderInput
    
    
    private func ensureSize(_ count: Int) throws {
        if try size() < count {
            throw BinaryReaderError.outOfRange
        }
    }
}

public extension BinaryReader {
    func remainingSize() throws -> Int {
        try size() - offset
    }
    
    func ensureRemainingSize(_ count: Int) throws {
        try ensureSize(offset + count)
    }
    
    mutating func read(to buffer: UnsafeMutableRawBufferPointer) throws {
        try peek(to: buffer, offset: offset)
        try seek(offset + buffer.count)
    }
    
    mutating func skip(_ count: Int) throws {
        try seek(offset + count)
    }
    
    func resetted() throws -> BinaryReader {
        var copy = self
        copy.reset()
        return copy
    }
}

public extension BinaryReader {
    func peek(at: Range<Int>) throws -> Data {
        let requiredInputSize = at.lowerBound + at.count
        try ensureSize(requiredInputSize)

        var data = Data(repeating: 0, count: at.count)
        try data.withUnsafeMutableBytes {
            try peek(to: $0, offset: at.lowerBound)
        }
        return data
    }
    
    func peek<T>(offset: Int) throws -> T {
        let range = Range(offset: offset, length: MemoryLayout<T>.stride)
        let data = try peek(at: range)
        return data.pod(adopting: T.self)
    }
    
    func peekUInt8(offset: Int) throws -> UInt8 {
        try peek(offset: offset)
    }
    
    func peekUInt16(offset: Int) throws -> UInt16 {
        try peek(offset: offset)
    }
    
    func peekUInt32(offset: Int) throws -> UInt32 {
        try peek(offset: offset)
    }
    
    func peekUInt64(offset: Int) throws -> UInt64 {
        try peek(offset: offset)
    }
    
    func peekDefaultUInt(offset: Int) throws -> UInt {
        try peek(offset: offset)
    }
    
    func peekInt8(offset: Int) throws -> Int8 {
        try peek(offset: offset)
    }
    
    func peekInt16(offset: Int) throws -> Int16 {
        try peek(offset: offset)
    }
    
    func peekInt32(offset: Int) throws -> Int32 {
        try peek(offset: offset)
    }
    
    func peekInt64(offset: Int) throws -> Int64 {
        try peek(offset: offset)
    }
    
    func peekDefaultInt(offset: Int) throws -> Int {
        try peek(offset: offset)
    }
}

public extension BinaryReader {
    mutating func read(count: Int) throws -> Data {
        let data = try peek(at: Range(offset: offset, length: count))
        try seek(offset + count)
        return data
    }
    
    mutating func read(maxCount: Int) throws -> Data {
        let remainingSize = try remainingSize()
        if maxCount <= remainingSize {
            return try read(count: maxCount)
        } else {
            let count = min(maxCount, remainingSize)
            return try read(count: count)
        }
    }
    
    mutating func read<T>() throws -> T {
        let data = try read(count: MemoryLayout<T>.stride)
        return data.pod(adopting: T.self)
    }
    
    mutating func readUInt8() throws -> UInt8 {
        try read()
    }
    
    mutating func readUInt16() throws -> UInt16 {
        try read()
    }
    
    mutating func readUInt32() throws -> UInt32 {
        try read()
    }
    
    mutating func readUInt64() throws -> UInt64 {
        try read()
    }
    
    mutating func readDefaultUInt() throws -> UInt {
        try read()
    }
    
    mutating func readInt8() throws -> Int8 {
        try read()
    }
    
    mutating func readInt16() throws -> Int16 {
        try read()
    }
    
    mutating func readInt32() throws -> Int32 {
        try read()
    }
    
    mutating func readInt64() throws -> Int64 {
        try read()
    }
    
    mutating func readDefaultInt() throws -> Int {
        try read()
    }
}

public enum BinaryReaderError: Error {
    case outOfRange
}
