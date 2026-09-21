//  MIT License
//
//  Copyright (c) 2022 Alkenso (Vladimir Vashurkin)
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

/// Debounces scheduled work: the work is executed only after `delay` has passed since the last `schedule` call.
/// Each `schedule` call cancels previously scheduled work (either queue-based or async) if it is not running yet.
public final class DebounceContext: Sendable {
    private let delay: TimeInterval
    private let pending = Atomic<Pending?>(wrappedValue: nil)
    
    public init(delay: TimeInterval) {
        self.delay = delay
    }
    
    /// Schedule some work to be executed on the queue after the delay.
    /// Cancels previous scheduled work if it is not running yet.
    public func schedule(on queue: DispatchQueue, execute: sending @escaping () -> Void) {
        let item = DispatchWorkItem(block: execute)
        pending.exchange(.workItem(item))?.cancel()
        queue.asyncAfter(delay: delay, execute: item)
    }
    
    /// Schedule some async work to be executed after the delay.
    /// Cancels previous scheduled work if it is not running yet.
    public func schedule(
        @_inheritActorContext operation: sending @escaping () async -> Void
    ) {
        let task = Task.after(.timeInterval(delay)) { await operation() }
        pending.exchange(.task(task))?.cancel()
    }
    
    /// Cancels scheduled work if it is not running yet.
    public func cancel() {
        pending.exchange(nil)?.cancel()
    }
    
    private enum Pending {
        case workItem(DispatchWorkItem)
        case task(Task<Void, Never>)
        
        func cancel() {
            switch self {
            case .workItem(let item): item.cancel()
            case .task(let task): task.cancel()
            }
        }
    }
}

extension DispatchQueue {
    /// Schedule some work to be executed on queue.
    /// Cancels previous execution block if it not running yet.
    public func debounce(with context: DebounceContext, execute: sending @escaping () -> Void) {
        context.schedule(on: self, execute: execute)
    }
}
