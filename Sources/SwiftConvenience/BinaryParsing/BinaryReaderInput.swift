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


public protocol BinaryReaderInput {
    func readBytes(to: UnsafeMutableRawBufferPointer, at range: Range<Int>) throws
    func count() -> Int
}

public struct AnyBinaryReaderInput: BinaryReaderInput {
    private var _readBytes: (_ to: UnsafeMutableRawBufferPointer, _ range: Range<Int>) throws -> Void
    private var _count: () -> Int
    
    
    public init(
        readBytes: @escaping (UnsafeMutableRawBufferPointer, Range<Int>) throws -> Void,
        count: @escaping () -> Int
    ) {
        _readBytes = readBytes
        _count = count
    }
    
    public func readBytes(to: UnsafeMutableRawBufferPointer, at range: Range<Int>) throws {
        try _readBytes(to, range)
    }
    
    public func count() -> Int {
        _count()
    }
}

public extension BinaryReader {
    init(data: Data) {
        self.init(
            AnyBinaryReaderInput(
                readBytes: { dstPtr, range in
                    if range.count != data.copyBytes(to: dstPtr, from: range) {
                        throw BinaryWriterError.outOfRange
                    }
                },
                count: { data.count }
            )
        )
    }
}
