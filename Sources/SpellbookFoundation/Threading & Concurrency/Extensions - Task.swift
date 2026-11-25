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

import Combine
import Foundation

extension Task {
    @discardableResult
    public static func after(
        _ delay: Duration,
        @_inheritActorContext operation: sending @escaping @isolated(any) () async throws(Failure) -> Success
    ) -> Task where Failure == Error {
        Self {
            try await Task<Never, Never>.sleep(for: delay)
            return try await operation()
        }
    }
    
    @discardableResult
    public static func after(
        _ delay: Duration,
        @_inheritActorContext operation: sending @escaping @isolated(any) () async -> Void
    ) -> Task where Success == Void, Failure == Never {
        Self {
            do {
                try await Task<Never, Never>.sleep(for: delay)
                return await operation()
            } catch {}
        }
    }
    
    /// Runs the operation up to `maxCount` times, including the immediate call if requested.
    public static func periodically(
        every interval: Duration,
        immediately: Bool = false,
        @Clamped(1...Int.max) maxCount: Int = .max,
        name: String? = nil,
        priority: TaskPriority? = nil,
        @_inheritActorContext operation: @escaping @Sendable @isolated(any) () -> Void
    ) -> Task where Success == Void, Failure == Never {
        Self(name: name, priority: priority) {
            if immediately {
                await operation()
            }
            
            for _ in (immediately ? 1 : 0)..<maxCount {
                do {
                    try await Task<Never, Never>.sleep(for: interval)
                    await operation()
                } catch {
                    return
                }
            }
        }
    }
}

extension Task: @retroactive Cancellable {}
extension Task: SafeCancellable {}
