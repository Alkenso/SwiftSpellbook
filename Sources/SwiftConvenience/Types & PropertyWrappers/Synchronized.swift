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


public enum SynchronizationType {
    case serial(DispatchQoS)
    case concurrent(DispatchQoS)
    case custom(DispatchQueue)
    
    public static var serial: SynchronizationType { .serial(.default) }
    public static var concurrent: SynchronizationType { .serial(.default) }
}

/// Wrapper around DispatchQueue for convenient and safe multithreaded access to any value.
public final class Synchronized<Value> {
    private let _queue: DispatchQueue
    private var _value: Value
    
    public static func serial(_ value: Value, qos: DispatchQoS = .default) -> Synchronized {
        Synchronized(value, synchronization: .serial(qos))
    }
    
    public static func concurrent(_ value: Value, qos: DispatchQoS = .default) -> Synchronized {
        Synchronized(value, synchronization: .concurrent(qos))
    }
    
    public init(_ value: Value, synchronization: SynchronizationType) {
        _value = value
        
        let queueLabel = String(describing: Self.self)
        switch synchronization {
        case .serial(let qos):
            _queue = DispatchQueue(label: queueLabel, qos: qos)
        case .concurrent(let qos):
            _queue = DispatchQueue(label: queueLabel, qos: qos, attributes: .concurrent)
        case .custom(let queue):
            _queue = queue
        }
    }
    
    public func read<R>(_ reader: (Value) throws -> R) rethrows -> R {
        try _queue.sync { try reader(_value) }
    }
    
    public func write<R>(_ writer: (inout Value) throws -> R) rethrows -> R {
        try _queue.sync(flags: .barrier) { try writer(&_value) }
    }
    
    public func writeAsync(_ writer: @escaping (inout Value) -> Void) {
        _queue.async(flags: .barrier) { writer(&self._value) }
    }
}

public extension Synchronized {
    convenience init(_ synchronization: SynchronizationType) where Value: ExpressibleByArrayLiteral {
        self.init([], synchronization: synchronization)
    }
    
    convenience init(_ synchronization: SynchronizationType) where Value: ExpressibleByDictionaryLiteral {
        self.init([:], synchronization: synchronization)
    }
}

public extension Synchronized {
    func read() -> Value {
        read { $0 }
    }
    
    func read<R>(_ keyPath: KeyPath<Value, R>) -> R {
        read { $0[keyPath: keyPath] }
    }
    
    func write(_ value: Value) {
        write { $0 = value }
    }
    
    func write<S>(_ subValue: S, at keyPath: WritableKeyPath<Value, S>) {
        writeAsync { $0[keyPath: keyPath] = subValue }
    }
    
    func exchange(_ value: Value) -> Value {
        write {
            let existing = $0
            $0 = value
            return existing
        }
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
