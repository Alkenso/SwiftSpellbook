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

public protocol BinaryWriterOutput: AnyObject {
    func writeBytes(from: UnsafeBufferPointer<UInt8>, at offset: Int) throws
    func size() throws -> Int
}

public class AnyBinaryWriterOutput: BinaryWriterOutput {
    private var _writeBytes: (_ from: UnsafeBufferPointer<UInt8>, _ offset: Int) throws -> Void
    private var _size: () throws -> Int
    
    public init(
        writeBytes: @escaping (UnsafeBufferPointer<UInt8>, Int) throws -> Void,
        size: @escaping () -> Int
    ) {
        _writeBytes = writeBytes
        _size = size
    }
    
    public func writeBytes(from: UnsafeBufferPointer<UInt8>, at offset: Int) throws {
        try _writeBytes(from, offset)
    }
    
    public func size() throws -> Int {
        try _size()
    }
}

public class BinaryWriterDataOutput: BinaryWriterOutput {
    public private(set) var data: Data
    
    public init(data: Data = Data()) {
        self.data = data
    }
    
    public func writeBytes(from: UnsafeBufferPointer<UInt8>, at offset: Int) throws {
        guard offset >= 0 else { throw BinaryParsingError.outOfRange }

        let appendCount = (offset + from.count) - data.count
        if appendCount > 0 {
            data += Data(repeating: 0, count: appendCount)
        }
        // `data` may be a slice, whose indices do not start at zero.
        data.replaceSubrange(Range(offset: data.startIndex + offset, length: from.count), with: from)
    }
    
    public func size() -> Int {
        data.count
    }
}

public class BinaryWriterFileOutput: BinaryWriterOutput {
    private let fileHandle: FileHandle
    private var fileSize: Int
    private var fileOffset: Int?
    
    public convenience init(url: URL) throws {
        try self.init(fileHandle: FileHandle(forWritingTo: url))
    }
    
    public init(fileHandle: FileHandle) throws {
        let size = try fileHandle.seekToEnd()
        guard let size = Int(exactly: size) else { throw BinaryParsingError.outOfRange }
        
        self.fileHandle = fileHandle
        self.fileSize = size
        self.fileOffset = size
    }
    
    public func writeBytes(from: UnsafeBufferPointer<UInt8>, at offset: Int) throws {
        guard offset >= 0, from.count <= Int.max - offset else {
            throw BinaryParsingError.outOfRange
        }
        guard !from.isEmpty else { return }
        
        if fileOffset != offset {
            fileOffset = nil
            try fileHandle.seek(toOffset: UInt64(offset))
        }
        
        fileOffset = nil
        try fileHandle.write(contentsOf: Data(from))
        fileOffset = offset + from.count
        fileSize = max(fileSize, fileOffset!)
    }
    
    public func size() -> Int {
        fileSize
    }
}
