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


/// Resource wrapper that follows the RAII rule: 'Resource acquisition is initialization'.
/// It is a resource wrapper that performs cleanup when resource is not used anymore.
public class Resource<T> {
    public var value: T
    
    private init(_ value: T, cleanup: @escaping (T) -> Void) {
        self.value = value
        _cleanup = cleanup
    }
    
    /// Immediately perform cleanup action.
    func forceCleanup() {
        let cleanup = __cleanup.exchange { _ in }
        cleanup(value)
    }
    
    /// Disables cleanup action when Resource is freed.
    func cancelCleanup() {
        _cleanup = { _ in }
    }
    
    deinit {
        _cleanup(value)
    }
    
    @Atomic private var _cleanup: (T) -> Void
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

/// Performs action on deinit.
public typealias DeinitAction = Resource<Void>
public extension Resource where T == Void {
    convenience init(_ onDeinit: @escaping () -> Void) {
        self.init((), cleanup: onDeinit)
    }
    
    /// Perform the action when the instance is freed.
    static func onDeinit(_ action: @escaping () -> Void) -> DeinitAction {
        Resource(action)
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
        let owned = TemporaryDirectory().uniqueFile(name: url.lastPathComponent)
        try owned.createDirectoryTree()
        try FileManager.default.moveItem(at: url, to: owned.url)
        return raii(location: owned.url)
    }
}

extension Resource: Equatable where T: Equatable {
    public static func == (lhs: Resource<T>, rhs: Resource<T>) -> Bool {
        lhs.value == rhs.value
    }
}

extension Resource: Comparable where T: Comparable {
    public static func < (lhs: Resource<T>, rhs: Resource<T>) -> Bool {
        lhs.value < rhs.value
    }
}

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension Resource: Identifiable where T: Identifiable {
    public var id: T.ID { value.id }
}
