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
import os

/// Wrapper around DispatchQueue for convenient and safe multithreaded access to the value.
public final class Synchronized<Value> {
    public enum Primitive {
        case unfair
        case rwlock
        
        case serial
        case concurrent
        case custom(DispatchQueue)
    }
    
    private let lock: SynchronizedLocking
    private var value: Value
    
    public init(_ primitive: Primitive, _ value: Value) {
        self.value = value
        
        self.lock = switch primitive {
        case .unfair:
            if #available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *) {
                OSAllocatedUnfairLock()
            } else {
                UnfairLock()
            }
        case .rwlock:
            RWLock()
        case .serial:
            DispatchQueue(label: "\(Self.self).queue", autoreleaseFrequency: .workItem)
        case .concurrent:
            DispatchQueue(label: "\(Self.self).queue", attributes: .concurrent, autoreleaseFrequency: .workItem)
        case .custom(let queue):
            queue
        }
    }
    
    public func read<R>(_ reader: (Value) throws -> R) rethrows -> R {
        try lock.withReadLock { try reader(value) }
    }
    
    public func write<R>(_ writer: (inout Value) throws -> R) rethrows -> R {
        try lock.withWriteLock { try writer(&value) }
    }
    
    public func write(_ writer: @escaping (inout Value) -> Void) {
        lock.withAsyncWriteLock { writer(&self.value) }
    }
}

extension Synchronized {
    public func read() -> Value {
        read { $0 }
    }
    
    public func read<R>(at keyPath: KeyPath<Value, R>) -> R {
        read { $0[keyPath: keyPath] }
    }
    
    public func write(_ value: Value) {
        write { $0 = value }
    }
    
    public func write<S>(at keyPath: WritableKeyPath<Value, S>, _ subValue: S) {
        write { $0[keyPath: keyPath] = subValue }
    }
    
    public func exchange(_ value: Value) -> Value {
        write {
            let existing = $0
            $0 = value
            return existing
        }
    }
}

extension Synchronized {
    public convenience init(_ primitive: Primitive) where Value: ExpressibleByArrayLiteral {
        self.init(primitive, [])
    }
    
    public convenience init(_ primitive: Primitive) where Value: ExpressibleByDictionaryLiteral {
        self.init(primitive, [:])
    }
}

extension Synchronized {
    public convenience init<T>(_ primitive: Primitive) where Value == T? {
        self.init(primitive, nil)
    }
    
    public func initialize<T>(produceValue: () throws -> T) rethrows -> T where Value == T? {
        try write {
            if let value = $0 {
                return value
            } else {
                let newValue = try produceValue()
                $0 = newValue
                return newValue
            }
        }
    }
    
    public func initialize<T>(_ value: T) -> T where Value == T? {
        initialize { value }
    }
}

extension Synchronized: _ValueUpdateWrapping {
    public func _readValue<R>(body: (Value) -> R) -> R {
        read(body)
    }
    
    public func _updateValue<R>(body: (inout Value) -> R) -> R {
        write(body)
    }
}

public extension Synchronized where Value: AdditiveArithmetic {
    static func + (lhs: Synchronized, rhs: Value) -> Value {
        lhs.read() + rhs
    }
    
    static func += (lhs: inout Synchronized, rhs: Value) {
        lhs.write { $0 += rhs }
    }
    
    static func - (lhs: Synchronized, rhs: Value) -> Value {
        lhs.read() - rhs
    }
    
    static func -= (lhs: inout Synchronized, rhs: Value) {
        lhs.write { $0 -= rhs }
    }
}

public extension Synchronized where Value: Numeric {
    static func * (lhs: Synchronized, rhs: Value) -> Value {
        lhs.read() * rhs
    }
    
    static func *= (lhs: inout Synchronized, rhs: Value) {
        lhs.write { $0 *= rhs }
    }
}

public extension Synchronized where Value: BinaryInteger {
    static func / (lhs: Synchronized, rhs: Value) -> Value {
        lhs.read() / rhs
    }
    
    static func /= (lhs: inout Synchronized, rhs: Value) {
        lhs.write { $0 /= rhs }
    }
}

public extension Synchronized where Value: FloatingPoint {
    static func / (lhs: Synchronized, rhs: Value) -> Value {
        lhs.read() / rhs
    }
    
    static func /= (lhs: inout Synchronized, rhs: Value) {
        lhs.write { $0 /= rhs }
    }
}

// MARK: - Locking

private protocol SynchronizedLocking {
    func withWriteLock<R>(_ body: () throws -> R) rethrows -> R
    
    func withReadLock<R>(_ body: () throws -> R) rethrows -> R
    func withAsyncWriteLock(_ body: @escaping () -> Void)
}

extension SynchronizedLocking {
    func withReadLock<R>(_ body: () throws -> R) rethrows -> R {
        try withWriteLock(body)
    }
    
    func withAsyncWriteLock(_ body: @escaping () -> Void) {
        withWriteLock(body)
    }
}

@available(macOS, deprecated: 13.0, message: "Use `UnfairLockStorage`")
@available(iOS, deprecated: 16.0, message: "Use `UnfairLockStorage`")
@available(watchOS, deprecated: 9.0, message: "Use `UnfairLockStorage`")
@available(tvOS, deprecated: 16.0, message: "Use `UnfairLockStorage`")
extension UnfairLock: SynchronizedLocking {
    func withWriteLock<R>(_ body: () throws -> R) rethrows -> R {
        try withLock(body)
    }
}

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
extension OSAllocatedUnfairLock: SynchronizedLocking where State == Void {
    func withWriteLock<R>(_ body: () throws -> R) rethrows -> R {
        try withLock { try body() }
    }
}

extension RWLock: SynchronizedLocking {}

extension DispatchQueue: SynchronizedLocking {
    func withWriteLock<R>(_ body: () throws -> R) rethrows -> R {
        try sync(flags: .barrier, execute: body)
    }
    
    func withReadLock<R>(_ body: () throws -> R) rethrows -> R {
        try sync(execute: body)
    }
    
    func withAsyncWriteLock(_ body: @escaping () -> Void) {
        async(flags: .barrier, execute: body)
    }
}
