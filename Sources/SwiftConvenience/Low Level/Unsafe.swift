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

/// Checks if memory of instances is equal. Generic version of memcmp.
public func unsafeMemoryEquals<T>(_ lhs: T, _ rhs: T) -> Bool {
    withUnsafeBytes(of: lhs) { lhsBuffer in
        withUnsafeBytes(of: rhs) { rhsBuffer in
            lhsBuffer.elementsEqual(rhsBuffer)
        }
    }
}

public protocol CPointer {
    /// Returns true is pointer is 0x0, false otherwise.
    var isNull: Bool { get }
}

public extension CPointer {
    /// Returns nil instead self if pointer is null.
    var nullable: Self? { isNull ? nil : self }
}

extension UnsafePointer: CPointer {
    public var isNull: Bool { self == Self(bitPattern: 0) }
}

extension UnsafeRawPointer: CPointer {
    public var isNull: Bool { self == Self(bitPattern: 0) }
}

extension UnsafeBufferPointer: CPointer {
    public var isNull: Bool { baseAddress == nil }
}

extension UnsafeRawBufferPointer: CPointer {
    public var isNull: Bool { baseAddress == nil }
}

extension UnsafeMutablePointer: CPointer {
    public var isNull: Bool { self == Self(bitPattern: 0) }
}

extension UnsafeMutableRawPointer: CPointer {
    public var isNull: Bool { self == Self(bitPattern: 0) }
}

extension UnsafeMutableBufferPointer: CPointer {
    public var isNull: Bool { baseAddress == nil }
}

extension UnsafeMutableRawBufferPointer: CPointer {
    public var isNull: Bool { baseAddress == nil }
}

extension AutoreleasingUnsafeMutablePointer: CPointer {
    public var isNull: Bool { self == Self(bitPattern: 0) }
}

public extension UnsafeMutablePointer {
    func bzero() {
        UnsafeMutableRawPointer(self).bzero(MemoryLayout<Pointee>.stride)
    }
}

public extension UnsafeMutableRawPointer {
    func bzero(_ size: Int) {
        Darwin.bzero(self, size)
    }
}

public extension UnsafeMutableBufferPointer {
    func bzero() {
        baseAddress?.bzero()
    }
}

public extension UnsafeMutableRawBufferPointer {
    func bzero() {
        baseAddress?.bzero(count)
    }
}

public extension AutoreleasingUnsafeMutablePointer {
    func bzero() {
        UnsafeMutablePointer(mutating: self).bzero()
    }
}
