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
    public var count: Int { _input.count() }
    public private(set) var offset: Int = 0
    public var remainingCount: Int { count - offset }
    
    
    public init(_ source: BinaryReaderInput) {
        _input = source
    }
    
    public func peek(at: Range<Int>) throws -> Data {
        let upperBound = at.lowerBound + at.count
        try ensureCapacity(upperBound)
        
        var data = Data(repeating: 0, count: at.count)
        try data.withUnsafeMutableBytes {
            try _input.readBytes(to: $0, at: at)
        }
        return data
    }
    
    public mutating func read(count: Int) throws -> Data {
        let data = try peek(count: count)
        offset += count
        return data
    }
    
    public mutating func skip(_ count: Int) throws {
        try ensureRemainingCapacity(count)
        
        offset += count
    }
    
    public mutating func seek(_ offset: Int) throws {
        try ensureCapacity(offset)
        
        self.offset = offset
    }
    
    // MARK: Private
    private let _input: BinaryReaderInput
    
    
    private func ensureCapacity(_ count: Int) throws {
        if count > _input.count() {
            throw BinaryDecoderError.outOfRange
        }
    }
    
    private func ensureRemainingCapacity(_ count: Int) throws {
        try ensureCapacity(offset + count)
    }
}

public extension BinaryReader {
    func peek(count: Int) throws -> Data {
        try peek(at: 0..<count)
    }
    
    func peek<T>() throws -> T {
        let data = try peek(count: MemoryLayout<T>.stride)
        return data.pod(adopting: T.self)
    }
    
    func peekUInt8() throws -> UInt8 {
        try peek()
    }
    
    func peekUInt16() throws -> UInt16 {
        try peek()
    }
    
    func peekUInt32() throws -> UInt32 {
        try peek()
    }
    
    func peekUInt64() throws -> UInt64 {
        try peek()
    }
    
    func peekDefaultUInt() throws -> UInt {
        try peek()
    }
    
    func peekInt8() throws -> Int8 {
        try peek()
    }
    
    func peekInt16() throws -> Int16 {
        try peek()
    }
    
    func peekInt32() throws -> Int32 {
        try peek()
    }
    
    func peekInt64() throws -> Int64 {
        try peek()
    }
    
    func peekDefaultInt() throws -> Int {
        try peek()
    }
}

public extension BinaryReader {
    mutating func read(maxCount: Int) throws -> Data {
        if maxCount <= remainingCount {
            return try read(count: maxCount)
        } else {
            let count = min(maxCount, remainingCount)
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

public extension BinaryReader {
    mutating func reset() {
        try? seek(0)
    }
    
    func resetted() -> Self {
        var copy = self
        copy.reset()
        return copy
    }
}

public enum BinaryDecoderError: Error {
    case outOfRange
}
