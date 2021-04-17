import Foundation


public enum SynchronizationType {
    case serial
    case concurrent
    case custom(DispatchQueue)
}

/// Wrapper around DispatchQueue for convenient and safe multithreaded access to any value.
public final class Synchronized<Value> {
    private let _queue: DispatchQueue
    private var _value: Value
    
    public var wrappedValue: Value {
        get { read() }
        set { write(newValue) }
    }
    
    public static func serial(_ value: Value) -> Synchronized {
        Synchronized(value, synchronization: .serial)
    }
    
    public static func concurrent(_ value: Value) -> Synchronized {
        Synchronized(value, synchronization: .concurrent)
    }
    
    public init(_ value: Value, synchronization: SynchronizationType) {
        _value = value
        
        let queueLabel = String(describing: Self.self)
        switch synchronization {
        case .serial:
            _queue = DispatchQueue(label: queueLabel)
        case .concurrent:
            _queue = DispatchQueue(label: queueLabel, attributes: .concurrent)
        case .custom(let queue):
            _queue = queue
        }
    }
    
    public func read<R>(_ reader: (Value) throws -> R) rethrows -> R {
        try _queue.sync { return try reader(_value) }
    }
    
    public func write<R>(_ writer: (inout Value) throws -> R) rethrows -> R {
        try _queue.sync(flags: .barrier) { return try writer(&_value) }
    }
    
    public func writeAsync(_ writer: @escaping (inout Value) -> Void) {
        _queue.async(flags: .barrier) { writer(&self._value) }
    }
}

public extension Synchronized {
    func read() -> Value {
        read(\.self)
    }
    
    func read<R>(_ keyPath: KeyPath<Value, R>) -> R {
        read { $0[keyPath: keyPath] }
    }
    
    func write(_ value: Value) {
        write(value, at: \.self)
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
