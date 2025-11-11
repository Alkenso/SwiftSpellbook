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
import Synchronization

/// Wrapper around DispatchQueue for convenient and safe multithreaded access to the value.
public final class Synchronized<Value>: @unchecked Sendable {
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
            UnfairLock()
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
    
    public func read<R>(_ reader: (Value) throws -> sending R) rethrows -> sending R {
        try lock.withReadLock { try reader(value) }
    }
    
    public func readUnchecked<R>(_ reader: (Value) throws -> R) rethrows -> R {
        try lock.withReadLock { try reader(value) }
    }
    
    public func write<R>(_ writer: (inout Value) throws -> sending R) rethrows -> sending R {
        try lock.withWriteLock { try writer(&value) }
    }
    
    public func writeUnchecked<R>(_ writer: (inout Value) throws -> R) rethrows -> R {
        try lock.withWriteLock { try writer(&value) }
    }
}

extension Synchronized {
    public func read() -> Value where Value: Sendable {
        read { $0 }
    }
    
    public func read<R: Sendable>(at keyPath: KeyPath<Value, R> & Sendable) -> R {
        read { $0[keyPath: keyPath] }
    }
    
    @discardableResult
    public func write(_ value: sending Value) -> sending Value {
        write { UncheckedSendable(exchange(&$0, with: value)) }.wrappedValue
    }
    
    public func write<S>(at keyPath: WritableKeyPath<Value, S> & Sendable, _ subValue: sending S) {
        write { $0[keyPath: keyPath] = subValue }
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
    
    public func initialize<T: Sendable>(produceValue: () throws -> T) rethrows -> T where Value == T? {
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
    
    public func initialize<T: Sendable>(_ value: T) -> T where Value == T? {
        initialize { value }
    }
}

extension Synchronized: _ValueUpdateWrapping {
    public func _readValue<R: Sendable>(body: (Value) -> R) -> R {
        read { body($0) }
    }
    
    public func _updateValue<R: Sendable>(body: (inout Value) -> R) -> R {
        write { body(&$0) }
    }
}

public extension Synchronized where Value: AdditiveArithmetic & Sendable {
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

public extension Synchronized where Value: Numeric & Sendable {
    static func * (lhs: Synchronized, rhs: Value) -> Value {
        lhs.read() * rhs
    }
    
    static func *= (lhs: inout Synchronized, rhs: Value) {
        lhs.write { $0 *= rhs }
    }
}

public extension Synchronized where Value: BinaryInteger & Sendable {
    static func / (lhs: Synchronized, rhs: Value) -> Value {
        lhs.read() / rhs
    }
    
    static func /= (lhs: inout Synchronized, rhs: Value) {
        lhs.write { $0 /= rhs }
    }
}

public extension Synchronized where Value: FloatingPoint & Sendable {
    static func / (lhs: Synchronized, rhs: Value) -> Value {
        lhs.read() / rhs
    }
    
    static func /= (lhs: inout Synchronized, rhs: Value) {
        lhs.write { $0 /= rhs }
    }
}

// MARK: - Locking

private protocol SynchronizedLocking {
    func withWriteLock<R, E: Error>(_ body: () throws(E) -> sending R) throws(E) -> sending R
    func withReadLock<R, E: Error>(_ body: () throws(E) -> sending R) throws(E) -> sending R
}

extension SynchronizedLocking {
    func withReadLock<R, E: Error>(_ body: () throws(E) -> sending R) throws(E) -> sending R {
        try withWriteLock(body)
    }
}

extension UnfairLock: SynchronizedLocking {
    func withWriteLock<R, E: Error>(_ body: () throws(E) -> sending R) throws(E) -> sending R {
        try withLock(body)
    }
}

extension RWLock: SynchronizedLocking {}

extension DispatchQueue: SynchronizedLocking {
    func withWriteLock<R, E: Error>(_ body: () throws(E) -> sending R) throws(E) -> sending R {
        try sync(flags: .barrier) { UncheckedSendable(Result(catching: body)) }.wrappedValue.get()
    }
    
    func withReadLock<R, E: Error>(_ body: () throws(E) -> sending R) throws(E) -> sending R {
        try sync { UncheckedSendable(Result(catching: body)) }.wrappedValue.get()
    }
}
