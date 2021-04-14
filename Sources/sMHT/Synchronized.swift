import Foundation


public final class Synchronized<Value> {
    private let _queue: DispatchQueue
    private var _value: Value
    
    public var wrappedValue: Value {
        get { read() }
        set { write(newValue) }
    }
    
    public static func serial(_ value: Value) -> Synchronized {
        Synchronized(value, concurrentReads: false)
    }
    
    public static func concurrent(_ value: Value) -> Synchronized {
        Synchronized(value, concurrentReads: true)
    }
    
    public convenience init(_ value: Value, concurrentReads: Bool = true) {
        self.init(
            value,
            queue: DispatchQueue(
                label: String(describing: Self.self),
                attributes: concurrentReads ? .concurrent : []
            )
        )
    }

    public init(_ value: Value, queue: DispatchQueue) {
        _value = value
        _queue = queue
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
}
