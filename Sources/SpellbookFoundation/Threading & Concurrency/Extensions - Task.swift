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
        _ body: @escaping () async throws -> R,
        completion: @escaping (Result<R, Error>) -> Void
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
        _ body: @escaping () async -> R,
        completion: @escaping (R) -> Void
    ) where Success == Void, Failure == Never {
        Task<Void, Never> {
            let result = await body()
            queue.async { completion(result) }
        }
    }
    
    public static func runWithCompletion(
        receiveOn queue: DispatchQueue? = nil,
        _ body: @escaping () async throws -> Void,
        completion: @escaping (Error?) -> Void
    ) where Success == Void, Failure == Never {
        runWithCompletion(receiveOn: queue, body) {
            completion($0.failure)
        }
    }
}

extension Task where Success == Never, Failure == Never {
    public static func sleep(forTimeInterval interval: TimeInterval) async throws {
        try await sleep(nanoseconds: UInt64(interval * TimeInterval(NSEC_PER_SEC)))
    }
    
    @available(macOS, deprecated: 13.0, message: "Use `sleep(for:)` method instead")
    @available(iOS, deprecated: 16.0, message: "Use `sleep(for:)` method instead")
    @available(watchOS, deprecated: 9.0, message: "Use `sleep(for:)` method instead")
    @available(tvOS, deprecated: 16.0, message: "Use `sleep(for:)` method instead")
    public static func sleep(seconds duration: Int) async throws {
        try await sleep(nanoseconds: UInt64(duration) * NSEC_PER_SEC)
    }
    
    @available(macOS, deprecated: 13.0, message: "Use `sleep(for:)` method instead")
    @available(iOS, deprecated: 16.0, message: "Use `sleep(for:)` method instead")
    @available(watchOS, deprecated: 9.0, message: "Use `sleep(for:)` method instead")
    @available(tvOS, deprecated: 16.0, message: "Use `sleep(for:)` method instead")
    public static func sleep(milliseconds duration: Int) async throws {
        try await sleep(nanoseconds: UInt64(duration) * NSEC_PER_MSEC)
    }
}

extension Task: Combine.Cancellable {}
