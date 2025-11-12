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

/// Executes synchronously the asynchronous method.
/// - Note: While this is not the best practice ever,
///         real-world tasks time to time require exactly this.
public func synchronouslyWithTask<R, E: Error>(_ action: sending @escaping () async throws(E) -> R) throws(E) -> R {
    let (group, result) = synchronouslyWithTask(action)
    group.wait()
    return try result.wrappedValue.get()!
}

/// Executes synchronously the asynchronous method.
/// - Note: While this is not the best practice ever,
///         real-world tasks time to time require exactly this.
public func synchronouslyWithTask<R, E: Error>(timeout: TimeInterval?, _ action: sending @escaping () async throws(E) -> R) throws(E) -> R? {
    guard let timeout else { return try synchronouslyWithTask(action) }
    let (group, result) = synchronouslyWithTask(action)
    _ = group.wait(timeout: .now() + timeout)
    return try result.wrappedValue.get()
}

private func synchronouslyWithTask<R, E: Error>(_ action: sending @escaping () async throws(E) -> R) -> (DispatchGroup, Atomic<Result<R?, E>>) {
    let group = DispatchGroup()
    group.enter()
    let result = Atomic<Result<R?, E>>(wrappedValue: .success(nil))
    Task {
        do {
            let r = try await action()
            _ = result.exchange(.success(r))
        } catch {
            _ = result.exchange(.failure(error as! E))
        }
        group.leave()
    }
    return (group, result)
}

/// Executes synchronously the asynchronous method.
/// - Note: While this is not the best practice ever,
///         real-world tasks time to time require exactly this.
public func synchronouslyWithCallback<R>(_ action: (_ callback: @escaping @Sendable (R) -> Void) -> Void) -> R {
    let (group, result) = synchronouslyWithCallback(action)
    group.wait()
    return result.wrappedValue!
}

/// Executes synchronously the asynchronous method.
/// - Note: While this is not the best practice ever,
///         real-world tasks time to time require exactly this.
public func synchronouslyWithCallback<R>(
    timeout: TimeInterval?,
    _ action: (_ callback: @escaping @Sendable (R) -> Void) -> Void
) -> R? {
    guard let timeout else { return synchronouslyWithCallback(action) }
    let (group, result) = synchronouslyWithCallback(action)
    _ = group.wait(timeout: .now() + timeout)
    return result.wrappedValue
}

private func synchronouslyWithCallback<R>(
    _ action: (_ callback: @escaping @Sendable (R) -> Void) -> Void
) -> (DispatchGroup, Atomic<R?>) {
    let group = DispatchGroup()
    group.enter()
    let result = Atomic<R?>(wrappedValue: nil)
    let once = AtomicFlag()
    action {
        guard !once.testAndSet() else {
            if !RunEnvironment.isXCTesting {
                assertionFailure("Completion called multiple times")
            }
            return
        }
        _ = result.exchange($0)
        group.leave()
    }
    return (group, result)
}
