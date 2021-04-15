import Foundation


@propertyWrapper
public final class Atomic<Value> {
    private let _value: Synchronized<Value>
    
    
    public init(wrappedValue: Value, synchronization: SynchronizationType = .serial) {
        _value = .init(wrappedValue, synchronization: synchronization)
    }
    
    public var wrappedValue: Value {
        get { _value.read { $0 } }
        set { _value.write { $0 = newValue } }
    }
    
    public func exchange(_ value: Value) -> Value {
        _value.exchange(value)
    }
}
