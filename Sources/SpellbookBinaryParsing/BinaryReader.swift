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

import SpellbookFoundation

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
            throw BinaryParsingError.outOfRange
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
    
    /// Peek some amount of data using `while` closure to determine when to stop.
    /// The data is stopped to be collected if `while` returns `false` or there is no more data.
    func peek(offset: Int = 0, while shouldProceed: (UInt8) -> Bool) throws -> Data {
        let size = try _input.size()
        
        var data = Data()
        var pos = offset
        let buffer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: 1)
        defer { buffer.deallocate() }
        while pos < size {
            try _input.readBytes(to: buffer, offset: pos)
            let value = buffer[0]
            guard shouldProceed(value) else { break }
            data.append(value)
            pos += 1
        }
        
        return data
    }
    
    func peek<T>(_ type: T.Type, offset: Int) throws -> T {
        try ensureTrivial(T.self)
        
        let range = Range(offset: offset, length: MemoryLayout<T>.stride)
        let data = try peek(at: range)
        return data.pod(adopting: T.self)
    }
    
    func peek<T>(offset: Int) throws -> T {
        try peek(T.self, offset: offset)
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
    
    func peekUInt(offset: Int) throws -> UInt {
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
    
    func peekInt(offset: Int) throws -> Int {
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
        let size = try remainingSize()
        if maxCount <= size {
            return try read(count: maxCount)
        } else {
            let count = min(maxCount, size)
            return try read(count: count)
        }
    }
    
    /// Read some amount of data using `while` closure to determine when to stop.
    /// The data is stopped to be collected if `while` returns `false` or there is no more data.
    mutating func read(offset: Int = 0, while shouldProceed: (UInt8) -> Bool) throws -> Data {
        let data = try peek(offset: offset, while: shouldProceed)
        try seek(offset + data.count)
        return data
    }
    
    mutating func read<T>(_ type: T.Type) throws -> T {
        try ensureTrivial(T.self)
        
        let data = try read(count: MemoryLayout<T>.stride)
        return data.pod(adopting: T.self)
    }
    
    mutating func read<T>() throws -> T {
        try read(T.self)
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
    
    mutating func readUInt() throws -> UInt {
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
    
    mutating func readInt() throws -> Int {
        try read()
    }
}
