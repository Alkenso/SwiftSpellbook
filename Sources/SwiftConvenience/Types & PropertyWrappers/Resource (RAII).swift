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
@dynamicMemberLookup
public class Resource<T> {
    /// In most cases prefer use of 'withValue' method.
    /// Note:
    /// Be careful copying the value or storing it in the separate variable.
    /// Swift optimizations may free Resource (and perform cleanup)
    /// in the place of last use of Resource, not the Resource.value place
    public var unsafeValue: T { _value }
    
    public init(_ value: T, cleanup: @escaping (T) -> Void) {
        _value = value
        _cleanup = cleanup
    }
    
    /// Immediately perform cleanup action.
    public func cleanup() {
        let cleanup = __cleanup.exchange { _ in }
        cleanup(_value)
    }
    
    /// Disables cleanup action when Resource is freed.
    @discardableResult
    public func release() -> T {
        _cleanup = { _ in }
        return _value
    }
    
    @discardableResult
    public func replaceCleanup(_ newCleanup: @escaping (T) -> Void) -> (T) -> Void {
        __cleanup.exchange(newCleanup)
    }
    
    deinit {
        _cleanup(_value)
    }
    
    private var _value: T
    @Atomic private var _cleanup: (T) -> Void
}

public extension Resource {
    /// Safe way accessing the value
    func withValue<R>(_ body: (T) throws -> R) rethrows -> R {
        try body(unsafeValue)
    }
    
    subscript<Local>(dynamicMember keyPath: KeyPath<T, Local>) -> Local {
        unsafeValue[keyPath: keyPath]
    }
}

public extension Resource {
    /// Create Resource wrapping value and performing cleanup block when the wrapper if freed.
    static func raii(_ value: T, cleanup: @escaping (T) -> Void) -> Resource {
        Resource(value, cleanup: cleanup)
    }
    
    /// Create Resource wrapping value and performing nothing when the wrapper if freed.
    static func stub(_ value: T) -> Resource {
        Resource(value, cleanup: { _ in })
    }
}

public extension Resource {
    /// Create Resource wrapping pointer. Deinitializes and deallocates it on cleanup.
    static func pointer<P>(_ ptr: T) -> Resource where T == UnsafeMutablePointer<P> {
        Resource(
            ptr,
            cleanup: {
                $0.deinitialize(count: 1)
                $0.deallocate()
            }
        )
    }
    
    /// Create Resource wrapping pointer.
    /// Allocated and initializes pointer on create,
    /// deinitializes and deallocates it on cleanup.
    static func pointer<P>(value: P) -> Resource where T == UnsafeMutablePointer<P> {
        let ptr = T.allocate(capacity: 1)
        ptr.initialize(to: value)
        return .pointer(ptr)
    }
    
    /// Create Resource wrapping pointer. Deinitializes and deallocates it on cleanup.
    static func pointer<P>(_ buffer: T) -> Resource where T == UnsafeMutableBufferPointer<P> {
        Resource(
            buffer,
            cleanup: {
                $0.baseAddress?.deinitialize(count: $0.count)
                $0.deallocate()
            }
        )
    }
    
    /// Create Resource wrapping pointer.
    /// Allocated and initializes pointer on create,
    /// deinitializes and deallocates it on cleanup.
    static func pointer<P, C: Collection>(values: C) -> Resource where T == UnsafeMutableBufferPointer<P>, C.Element == P {
        let ptr = T.allocate(capacity: values.count)
        _ = ptr.initialize(from: values)
        return .pointer(ptr)
    }
    
    /// Create Resource wrapping pointer. Deallocates it on cleanup.
    static func pointer(_ ptr: T) -> Resource where T == UnsafeMutableRawPointer {
        Resource(ptr, cleanup: { $0.deallocate() })
    }
    
    /// Create Resource wrapping pointer. Deallocates it on cleanup.
    static func pointer(_ buffer: T) -> Resource where T == UnsafeMutableRawBufferPointer {
        Resource(buffer, cleanup: { $0.deallocate() })
    }
}

/// Performs action on deinit.
public typealias DeinitAction = Resource<Void>
public extension Resource where T == Void {
    /// Perform the action when the instance is freed.
    convenience init(onDeinit: @escaping () -> Void) {
        self.init((), cleanup: onDeinit)
    }
    
    /// Perform the action when the instance is freed.
    static func onDeinit(_ action: @escaping () -> Void) -> DeinitAction {
        DeinitAction(onDeinit: action)
    }
}

public extension Resource where T == URL {
    /// Create Resource wrapping URL and removing it when the wrapper if freed.
    static func raii(location filesystemURL: URL) -> Resource {
        raii(filesystemURL) { try? FileManager.default.removeItem(at: $0) }
    }
    
    /// Create Resource wrapping URL and removing it when the wrapper if freed.
    /// The item will be moved into temporary location first.
    static func raii(moving url: URL) throws -> Resource {
        let owned = TemporaryDirectory.default.uniqueFile(basename: url.lastPathComponent)
        try FileManager.default.createDirectoryTree(for: owned)
        try FileManager.default.moveItem(at: url, to: owned)
        return raii(location: owned)
    }
}

extension Resource: Equatable where T: Equatable {
    public static func == (lhs: Resource<T>, rhs: Resource<T>) -> Bool {
        lhs._value == rhs._value
    }
}

extension Resource: Comparable where T: Comparable {
    public static func < (lhs: Resource<T>, rhs: Resource<T>) -> Bool {
        lhs._value < rhs._value
    }
}

extension Resource {
    public func store<C: RangeReplaceableCollection>(in collection: inout C) where C.Element == Resource {
        collection.append(self)
    }
}

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension Resource: Identifiable where T: Identifiable {
    public var id: T.ID { _value.id }
}

@available(macOS 10.15, iOS 13, tvOS 13.0, watchOS 6.0, *)
extension Resource: Cancellable {
    public func cancel() { cleanup() }
}
