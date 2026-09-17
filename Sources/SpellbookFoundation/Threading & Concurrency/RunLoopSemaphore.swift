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

import CoreFoundation
import Foundation

/// A one-shot semaphore that keeps its creating thread's run loop responsive while waiting.
///
/// After ``signal()`` is called, all current and future waits succeed.
/// Create and wait on the semaphore from the same thread.
public final class RunLoopSemaphore: @unchecked Sendable {
    private let lock = NSLock()
    private let runLoop: CFRunLoop
    private let source: CFRunLoopSource
    private var state = RunLoopSemaphoreState.idle
    private var nextWaitID: UInt = 0

    public init() {
        runLoop = CFRunLoopGetCurrent()
        var context = CFRunLoopSourceContext()
        context.perform = { _ in }
        source = CFRunLoopSourceCreate(nil, 0, &context)
        CFRunLoopAddSource(runLoop, source, .defaultMode)
    }

    deinit {
        CFRunLoopRemoveSource(runLoop, source, .defaultMode)
        CFRunLoopSourceInvalidate(source)
    }

    /// Waits indefinitely for the semaphore to be signaled while processing the creating run loop.
    @available(*, noasync)
    public func wait() {
        _ = wait(timeout: .distantFuture)
    }

    /// Waits for the semaphore to be signaled while processing the creating run loop.
    /// - Parameter timeout: The time at which to stop waiting.
    /// - Returns: `.success` if signaled, or `.timedOut` if the deadline elapsed first.
    @available(*, noasync)
    public func wait(timeout: DispatchTime) -> DispatchTimeoutResult {
        if isSignaled { return .success }

        while !isSignaled {
            let now = DispatchTime.now().uptimeNanoseconds
            guard now < timeout.uptimeNanoseconds else { return .timedOut }
            let remaining = timeout.uptimeNanoseconds - now
            let interval = CFTimeInterval(remaining) / CFTimeInterval(NSEC_PER_SEC)

            let waitID = lock.withLock { () -> UInt? in
                switch state {
                case .idle:
                    let waitID = nextWaitID
                    nextWaitID &+= 1
                    state = .waiting(waitID)
                    return waitID
                case .waiting:
                    preconditionFailure("RunLoopSemaphore does not support concurrent waits")
                case .signaled:
                    return nil
                }
            }
            guard let waitID else { return .success }

            CFRunLoopRunInMode(.defaultMode, interval, true)
            lock.withLock {
                switch state {
                case .waiting(let activeWaitID) where activeWaitID == waitID:
                    state = .idle
                case .signaled(activeWait: let activeWaitID?) where activeWaitID == waitID:
                    state = .signaled(activeWait: nil)
                default:
                    break
                }
            }
        }
        return .success
    }

    /// Signals the semaphore and wakes its creating run loop.
    public func signal() {
        let waitID = lock.withLock { () -> UInt? in
            switch state {
            case .waiting(let waitID):
                state = .signaled(activeWait: waitID)
                return waitID
            case .idle:
                state = .signaled(activeWait: nil)
                return nil
            case .signaled:
                return nil
            }
        }

        if let waitID {
            CFRunLoopPerformBlock(runLoop, CFRunLoopMode.defaultMode.rawValue) { [weak self] in
                self?.stopRunLoop(for: waitID)
            }
        }
        CFRunLoopWakeUp(runLoop)
    }

    private var isSignaled: Bool {
        lock.withLock {
            if case .signaled = state {
                return true
            }
            return false
        }
    }

    private func stopRunLoop(for waitID: UInt) {
        lock.withLock {
            guard case .signaled(activeWait: let activeWaitID?) = state,
                  activeWaitID == waitID else { return }
            CFRunLoopStop(runLoop)
        }
    }
}

private enum RunLoopSemaphoreState {
    case idle
    case waiting(UInt)
    case signaled(activeWait: UInt?)
}
