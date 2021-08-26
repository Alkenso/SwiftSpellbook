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
    func writeBytes(from: UnsafeRawBufferPointer, at offset: Int) throws
    func count() -> Int
}

public class AnyBinaryWriterOutput: BinaryWriterOutput {
    private var _writeBytes: (_ from: UnsafeRawBufferPointer, _ offset: Int) throws -> Void
    private var _count: () -> Int
    
    
    public init(
        writeBytes: @escaping (UnsafeRawBufferPointer, Int) throws -> Void,
        count: @escaping () -> Int
    ) {
        _writeBytes = writeBytes
        _count = count
    }
    
    public func writeBytes(from: UnsafeRawBufferPointer, at offset: Int) throws {
        try _writeBytes(from, offset)
    }
    
    public func count() -> Int {
        _count()
    }
}

public class DataOutput: BinaryWriterOutput {
    public var data: Data
    
    
    public init(data: Data = Data()) {
        self.data = data
    }
    
    public func writeBytes(from: UnsafeRawBufferPointer, at offset: Int) throws {
        data.insert(contentsOf: from, at: offset)
    }
    
    public func count() -> Int {
        data.count
    }
}
