import Foundation


// MARK: - ValueView

/// Wrapper that provides access to value. Useful when value is a struct that may be changed over time.
@dynamicMemberLookup
public final class ValueView<T> {
    public init(_ accessor: @escaping () -> T) {
        _accessor = accessor
    }
    
    public var value: T { _accessor() }
    
    public subscript<Property>(dynamicMember keyPath: KeyPath<T, Property>) -> Property {
        value[keyPath: keyPath]
    }
    
    // MARK: Private
    private let _accessor: () -> T
}


// MARK: - KeyValue

public struct KeyValue<Key, Value> {
    public var key: Key
    public var value: Value
    
    public init(_ key: Key, _ value: Value) {
        self.key = key
        self.value = value
    }
}

extension KeyValue: Codable where Key: Codable, Value: Codable {}
extension KeyValue: Equatable where Key: Equatable, Value: Equatable {}
extension KeyValue: Hashable where Key: Hashable, Value: Hashable {}
