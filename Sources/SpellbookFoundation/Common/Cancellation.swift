//  MIT License
//
//  Copyright (c) 2026 Alkenso (Vladimir Vashurkin)
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

public protocol SafeCancellable: Cancellable, Sendable {}

public final class Cancellation: SafeCancellable {
    private let implicit: Bool
    private let cancelClosure: @Sendable () -> Void
    private let isCancelled = AtomicFlag()
    
    public init(implicit: Bool = true, cancel: @escaping @Sendable () -> Void) {
        self.implicit = implicit
        self.cancelClosure = cancel
    }
    
    deinit {
        guard implicit else { return }
        cancel()
    }
    
    public func cancel() {
        guard !isCancelled.testAndSet() else { return }
        cancelClosure()
    }
    
    public func disarm() {
        _ = isCancelled.testAndSet()
    }
}

extension SafeCancellable {
    public func eraseToCancellation() -> Cancellation {
        Cancellation(cancel: cancel)
    }
}

extension Cancellable {
    public func unsafeEraseToCancellation() -> Cancellation {
        nonisolated(unsafe) let cancel = cancel
        return Cancellation { cancel() }
    }
}

extension SafeCancellable {
    /// Stores this cancellable instance in the specified collection.
    ///
    /// - Parameter collection: The collection in which to store this ``SafeCancellable``.
    public func store<C>(in collection: inout C) where C: RangeReplaceableCollection, C.Element == Cancellation {
        collection.append(eraseToCancellation())
    }
    
    public func store<ID: Hashable, C>(
        id: ID,
        in collection: inout [ID: C]
    ) where C: RangeReplaceableCollection, C.Element == Cancellation {
        store(in: &collection[id, default: C()])
    }
}
