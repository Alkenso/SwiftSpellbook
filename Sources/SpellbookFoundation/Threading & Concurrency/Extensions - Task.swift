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
    public static func runWithCompletion<R>(
        _: R.Type = R.self,
        receiveOn queue: DispatchQueue? = nil,
        _ body: sending @escaping () async throws -> R,
        completion: sending @escaping (Result<R, Error>) -> Void
    ) where Success == Void, Failure == Never {
        Task<Void, Never> {
            let result: Result<R, Error>
            do {
                result = .success(try await body())
            } catch {
                result = .failure(error)
            }
            queue.async { completion(result) }
        }
    }
    
    public static func runWithCompletion<R>(
        receiveOn queue: DispatchQueue? = nil,
        _ body: sending @escaping () async -> R,
        completion: sending @escaping (R) -> Void
    ) where Success == Void, Failure == Never {
        Task<Void, Never> {
            let result = await body()
            queue.async { completion(result) }
        }
    }
    
    public static func runWithCompletion(
        receiveOn queue: DispatchQueue? = nil,
        _ body: sending @escaping () async throws -> Void,
        completion: sending @escaping (Error?) -> Void
    ) where Success == Void, Failure == Never {
        runWithCompletion(receiveOn: queue, body) {
            completion($0.failure)
        }
    }
}

extension Task where Success == Never, Failure == Never {
    public static func sleep(forTimeInterval interval: TimeInterval) async throws {
        let nanoseconds = UInt64(interval * TimeInterval(NSEC_PER_SEC))
        if #available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *) {
            try await Task.sleep(for: .nanoseconds(nanoseconds))
        } else {
            // Workaround for issue: https://github.com/swiftlang/swift/issues/88259
            let innerTask = Task<Void, Error> { try await sleep(nanoseconds: nanoseconds) }
            return try await withTaskCancellationHandler {
                try await innerTask.value
            } onCancel: {
                innerTask.cancel()
            }
        }
    }
}

extension Task: Combine.Cancellable {}
