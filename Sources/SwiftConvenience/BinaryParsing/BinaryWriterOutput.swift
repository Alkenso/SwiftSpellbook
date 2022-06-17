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

public class DataBinaryWriterOutput: BinaryWriterOutput {
    public var data: Data
    
    public init(data: Data = Data()) {
        self.data = data
    }
    
    public func writeBytes(from: UnsafeBufferPointer<UInt8>, at offset: Int) throws {
        let appendCount = offset + from.count - data.count
        if appendCount > 0 {
            data += Data(repeating: 0, count: appendCount)
        }
        data.replaceSubrange(Range(offset: offset, length: from.count), with: from)
    }
    
    public func size() -> Int {
        data.count
    }
}
