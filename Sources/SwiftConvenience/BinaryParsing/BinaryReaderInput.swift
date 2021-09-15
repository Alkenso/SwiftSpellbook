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
    func readBytes(to: UnsafeMutableBufferPointer<UInt8>, offset: Int) throws
    func size() throws -> Int
}

public struct AnyBinaryReaderInput: BinaryReaderInput {
    private var _readBytes: (_ to: UnsafeMutableBufferPointer<UInt8>, _ offset: Int) throws -> Void
    private var _size: () -> Int
    
    
    public init(
        readBytes: @escaping (UnsafeMutableBufferPointer<UInt8>, Int) throws -> Void,
        size: @escaping () -> Int
    ) {
        _readBytes = readBytes
        _size = size
    }
    
    public func readBytes(to: UnsafeMutableBufferPointer<UInt8>, offset: Int) throws {
        try _readBytes(to, offset)
    }
    
    public func size() throws -> Int {
        _size()
    }
}

public extension BinaryReader {
    init(data: Data) {
        self.init(
            AnyBinaryReaderInput(
                readBytes: { dstPtr, offset in
                    let range = Range(offset: offset, length: dstPtr.count)
                    if dstPtr.count != data.copyBytes(to: dstPtr, from: range) {
                        throw BinaryParsingError.outOfRange
                    }
                },
                size: { data.count }
            )
        )
    }
}
