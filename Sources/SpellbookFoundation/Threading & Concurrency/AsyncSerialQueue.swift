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

import Foundation

public final class AsyncSerialQueue: @unchecked Sendable {
    private typealias Operation = () async -> Void
    
    private let continuation: AsyncStream<Operation>.Continuation
    private let worker: Task<Void, Never>

    public init() {
        let (stream, continuation) = AsyncStream<Operation>.makeStream()

        self.continuation = continuation
        self.worker = Task {
            for await operation in stream {
                await operation()
            }
        }
    }

    deinit {
        continuation.finish()
        worker.cancel()
    }
    
    public func async(@_inheritActorContext _ operation: sending @escaping () async -> Void) {
        continuation.yield(operation)
    }

    public func sync<R, E: Error>(_ operation: @concurrent () async throws(E) -> R) async throws(E) -> R {
        let resume = await withCheckedContinuation { resumeContinuation in
            continuation.yield {
                await withCheckedContinuation {
                    resumeContinuation.resume(returning: $0)
                }
            }
        }
        defer { resume.resume() }
        return try await operation()
    }
}
