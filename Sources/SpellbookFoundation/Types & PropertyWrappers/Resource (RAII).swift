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

import Combine
import Foundation

/// Resource wrapper that follows the RAII rule: 'Resource acquisition is initialization'.
/// It is a resource wrapper that performs cleanup when resource is not used anymore.
@propertyWrapper
@dynamicMemberLookup
public final class Resource<T>: @unchecked Sendable {
    private struct State {
        var value: T
        var freeFn: (T) -> Void
        var shouldFree = true
    }
    private let state: Synchronized<State>
    
    /// In most cases prefer use of 'withValue' method.
    /// Note:
    /// Be careful copying the value or storing it in the separate variable.
    /// Swift optimizations may free Resource (and perform cleanup)
    /// in the place of last use of Resource, not the Resource.unsafeValue place.
    public var wrappedValue: T { state.readUnchecked { $0.value } }
    
    public var projectedValue: Resource { self }
    
    public init(_ value: T, free: sending @escaping (T) -> Void) {
        self.state = .init(.unfair, .init(value: value, freeFn: free))
    }
    
    deinit {
        state.write {
            if $0.shouldFree {
                $0.freeFn($0.value)
            }
        }
    }
    
    /// Reset the resource value.
    ///
    /// Cleanup `current value` if `free` is `true`.
    /// Independently of `free` value, the `free` function passed into `init`
    /// will NOT be called for THIS value.
    ///
    /// If `newValue` is present, set it as `current one`.
    /// `newValue` will be freed using `free` function passed into `init`
    /// or on `deinit` or on next call to `reset`.
    @discardableResult
    public func reset(free: Bool = true, to newValue: T? = nil) -> T {
        let (currentValue, cleanup) = state.writeUnchecked {
            let currentValue = $0.value
            let currentCleanup = $0.freeFn
            
            if let newValue {
                $0.value = newValue
                $0.shouldFree = true
            } else {
                $0.shouldFree = false
            }
            
            let cleanup = free ? { currentCleanup(currentValue) } : {}
            
            return (currentValue, cleanup)
        }
        
        cleanup()
        
        return currentValue
    }
    
    /// Disables `free` action when Resource is deinited.
    ///
    /// Equivalent to `reset(free: false)`.
    @discardableResult
    public func release() -> T {
        reset(free: false)
    }
    
    /// Replace `cleanup` function with new one.
    @discardableResult
    public func replaceFree(_ newFree: sending @escaping (T) -> Void) -> sending (T) -> Void {
        state.writeUnchecked { exchange(&$0.freeFn, with: newFree) }
    }
}

extension Resource {
    /// Safe way accessing the value
    public func withValue<R, E: Error>(_ body: (T) throws(E) -> R) throws(E) -> R {
        try body(wrappedValue)
    }
    
    public subscript<Local>(dynamicMember keyPath: KeyPath<T, Local>) -> Local {
        wrappedValue[keyPath: keyPath]
    }
}

extension Resource {
    /// Create Resource wrapping value and performing cleanup block when the wrapper if freed.
    public static func raii(_ value: T, free: sending @escaping (T) -> Void) -> Resource {
        Resource(value, free: free)
    }
    
    /// Create Resource wrapping value and performing nothing when the wrapper if freed.
    public static func stub(_ value: T) -> Resource {
        Resource(value, free: { _ in })
    }
}

extension Resource {
    /// Create Resource wrapping pointer. Deinitializes and deallocates it on cleanup.
    public static func pointer<P>(_ ptr: T) -> Resource where T == UnsafeMutablePointer<P> {
        Resource(
            ptr,
            free: {
                $0.deinitialize(count: 1)
                $0.deallocate()
            }
        )
    }
    
    /// Create Resource wrapping pointer.
    /// Allocated and initializes pointer on create,
    /// deinitializes and deallocates it on cleanup.
    public static func pointer<P>(value: P) -> Resource where T == UnsafeMutablePointer<P> {
        let ptr = T.allocate(capacity: 1)
        ptr.initialize(to: value)
        return .pointer(ptr)
    }
    
    /// Create Resource wrapping pointer. Deinitializes and deallocates it on cleanup.
    public static func pointer<P>(_ buffer: T) -> Resource where T == UnsafeMutableBufferPointer<P> {
        Resource(
            buffer,
            free: {
                $0.baseAddress?.deinitialize(count: $0.count)
                $0.deallocate()
            }
        )
    }
    
    /// Create Resource wrapping pointer.
    /// Allocated and initializes pointer on create,
    /// deinitializes and deallocates it on cleanup.
    public static func pointer<P, C: Collection>(values: C) -> Resource where T == UnsafeMutableBufferPointer<P>, C.Element == P {
        let ptr = T.allocate(capacity: values.count)
        _ = ptr.initialize(from: values)
        return .pointer(ptr)
    }
    
    /// Create Resource wrapping pointer. Deallocates it on cleanup.
    public static func pointer(_ ptr: T) -> Resource where T == UnsafeMutableRawPointer {
        Resource(ptr, free: { $0.deallocate() })
    }
    
    /// Create Resource wrapping pointer. Deallocates it on cleanup.
    public static func pointer(_ buffer: T) -> Resource where T == UnsafeMutableRawBufferPointer {
        Resource(buffer, free: { $0.deallocate() })
    }
}

/// Performs action on deinit.
public typealias DeinitAction = Resource<Void>
extension Resource where T == Void {
    /// Perform the action when the instance is freed.
    public convenience init(onDeinit: sending @escaping () -> Void) {
        self.init((), free: onDeinit)
    }
    
    /// Perform the action when the instance is freed.
    public static func onDeinit(_ action: sending @escaping () -> Void) -> DeinitAction {
        DeinitAction(onDeinit: action)
    }
    
    /// Capture variable up to the end of `Resource` life time.
    public static func capturing(@UncheckedSendable _ object: Any) -> DeinitAction {
        DeinitAction { _ = object }
    }
    
    /// Add capture variable up to the end of `Resource` life time.
    public func capturing(_ object: Any) -> DeinitAction {
        .capturing((self, object))
    }
}

extension Resource where T == URL {
    /// Create Resource wrapping URL and removing it when the wrapper if freed.
    public static func raii(location filesystemURL: URL) -> Resource {
        raii(filesystemURL) { try? FileManager.default.removeItem(at: $0) }
    }
    
    /// Create Resource wrapping URL and removing it when the wrapper if freed.
    /// The item will be moved into temporary location first.
    public static func raii(moving url: URL) throws -> Resource {
        let owned = try TemporaryDirectory.bundle.setUp().file(prefix: url.lastPathComponent)
        try FileManager.default.moveItem(at: url, to: owned)
        return raii(location: owned)
    }
}

extension Resource: Equatable where T: Equatable {
    public static func == (lhs: Resource<T>, rhs: Resource<T>) -> Bool {
        lhs.wrappedValue == rhs.wrappedValue
    }
}

extension Resource: Comparable where T: Comparable {
    public static func < (lhs: Resource<T>, rhs: Resource<T>) -> Bool {
        lhs.wrappedValue < rhs.wrappedValue
    }
}

extension Resource {
    public func store<C: RangeReplaceableCollection>(in collection: inout C) where C.Element == Resource {
        collection.append(self)
    }
}

extension Resource: Identifiable where T: Identifiable {
    public var id: T.ID { wrappedValue.id }
}

extension Resource: Cancellable {
    public func cancel() { reset() }
}
