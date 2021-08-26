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
    public init(_ destination: BinaryWriterOutput) {
        _output = destination
    }
    
    public mutating func append(_ data: Data) throws {
        try write(data, at: _offset)
        _offset += data.count
    }
    
    public func write(_ data: Data, at offset: Int) throws {
        try data.withUnsafeBytes {
            try _output.writeBytes(from: $0, at: _offset)
        }
    }
    
    public mutating func seek(_ offset: Int) throws {
        _offset = offset
    }
    
    
    // MARK: Private
    private let _output: BinaryWriterOutput
    private var _offset: Int = 0
}

public extension BinaryWriter {
    mutating func append<T>(_ value: T) throws {
        let data = Data(pod: value)
        try append(data)
    }
    
    func write<T>(_ value: T, at offset: Int) throws {
        let data = Data(pod: value)
        try write(data, at: offset)
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
