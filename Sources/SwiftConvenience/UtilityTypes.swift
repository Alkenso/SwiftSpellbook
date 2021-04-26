import Foundation


// MARK: - CommonError

/// Type representing error for common situations.
public enum CommonError: Error {
    case fatal(String)
    case unexpected(String)
    case unwrapNil
    case invalidArgument
}

public extension Optional where Wrapped == Error {
    /// Unwraps Error that is expected to be not nil, but syntactically is optional.
    /// Often happens when bridge ObjC <-> Swift API.
    func unwrapSafely(unexpected: Error? = nil) -> Error {
        self ?? unexpected ?? CommonError.unexpected("Unexpected nil error.")
    }
}


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


// MARK: - DeinitAction

/// Performs action on deinit.
public final class DeinitAction {
    private let action: () -> Void
    
    
    public init(action: @escaping () -> Void) {
        self.action = action
    }
    
    deinit {
        action()
    }
}
