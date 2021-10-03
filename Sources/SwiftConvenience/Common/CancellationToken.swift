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


public class CancellationToken {
    private let _queue: DispatchQueue
    private let _onCancel: () -> Void
    
    @Atomic private var _cancelled = false
    private var _children = Synchronized<[CancellationToken]>(.serial)
    
    public var isCancelled: Bool { _cancelled }
    
    
    public init(on queue: DispatchQueue = .global(), cancel: @escaping () -> Void) {
        _queue = queue
        _onCancel = cancel
    }
    
    public func cancel() {
        guard !__cancelled.exchange(true) else { return }
        _queue.async(execute: _onCancel)
        _children.read().forEach { $0._queue.async(execute: $0.cancel) }
    }
    
    public func addChild(_ token: CancellationToken) {
        _children.writeAsync {
            if !self.isCancelled {
                $0.append(token)
            } else {
                token._queue.async(execute: token.cancel)
            }
        }
    }
}

extension CancellationToken {
    public convenience init() {
        self.init {}
    }
    
    public func addChild(on queue: DispatchQueue = .global(), cancel: @escaping () -> Void) {
        addChild(.init(on: queue, cancel: cancel))
    }
}


@available(macOS 10.15, iOS 13, tvOS 13.0, watchOS 6.0, *)
extension CancellationToken: Cancellable {}
