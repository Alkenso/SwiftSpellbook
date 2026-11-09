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

public protocol BinaryReaderInput {
    func readBytes(to: UnsafeMutableBufferPointer<UInt8>, offset: Int) throws
    func size() throws -> Int
}

public struct AnyBinaryReaderInput: BinaryReaderInput {
    private var _readBytes: (_ to: UnsafeMutableBufferPointer<UInt8>, _ offset: Int) throws -> Void
    private var _size: () throws -> Int
    
    public init(
        readBytes: @escaping (UnsafeMutableBufferPointer<UInt8>, Int) throws -> Void,
        size: @escaping () throws -> Int
    ) {
        _readBytes = readBytes
        _size = size
    }
    
    public func readBytes(to: UnsafeMutableBufferPointer<UInt8>, offset: Int) throws {
        try _readBytes(to, offset)
    }
    
    public func size() throws -> Int {
        try _size()
    }
}

extension BinaryReader {
    public init(data: Data) {
        self.init(BinaryReaderDataInput(data))
    }
    
    public init(file: URL) throws {
        try self.init(BinaryReaderFileInput(url: file))
    }
}

public struct BinaryReaderDataInput: BinaryReaderInput {
    private let data: Data
    
    public init(_ data: Data) {
        self.data = data
    }
    
    public func readBytes(to dstPtr: UnsafeMutableBufferPointer<UInt8>, offset: Int) throws {
        // `data` may be a slice, whose indices do not start at zero.
        guard offset >= 0, offset + dstPtr.count <= data.count else {
            throw BinaryParsingError.outOfRange
        }
        let range = Range(offset: data.startIndex + offset, length: dstPtr.count)
        if dstPtr.count != data.copyBytes(to: dstPtr, from: range) {
            throw BinaryParsingError.outOfRange
        }
    }
    
    public func size() -> Int {
        data.count
    }
}

public final class BinaryReaderFileInput: BinaryReaderInput {
    private let fileHandle: FileHandle
    private let fileSize: Int
    private var fileOffset: Int?
    
    public convenience init(url: URL) throws {
        try self.init(fileHandle: FileHandle(forReadingFrom: url))
    }
    
    public init(fileHandle: FileHandle) throws {
        let size = try fileHandle.seekToEnd()
        guard let size = Int(exactly: size) else { throw BinaryParsingError.outOfRange }
        
        self.fileHandle = fileHandle
        self.fileSize = size
        self.fileOffset = size
    }
    
    public func readBytes(to: UnsafeMutableBufferPointer<UInt8>, offset: Int) throws {
        guard offset >= 0, offset < fileSize, to.count <= fileSize - offset else {
            throw BinaryParsingError.outOfRange
        }
        guard !to.isEmpty else { return }
        
        if fileOffset != offset {
            fileOffset = nil
            try fileHandle.seek(toOffset: UInt64(offset))
        }
        
        fileOffset = nil
        let data = try fileHandle.read(upToCount: to.count) ?? Data()
        fileOffset = offset + data.count
        
        guard data.count == to.count else { throw BinaryParsingError.outOfRange }
        _ = data.copyBytes(to: to)
    }
    
    public func size() -> Int {
        fileSize
    }
}
