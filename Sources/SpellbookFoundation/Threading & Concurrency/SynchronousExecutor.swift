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
public struct SynchronousExecutor {
    public var name: String?
    public var timeout: TimeInterval?
    
    public init(_ name: String? = nil, timeout: TimeInterval?) {
        self.name = name
        self.timeout = timeout
    }
}

extension SynchronousExecutor {
    public func sync<R>(_ action: (@escaping @Sendable (Result<R, Error>) -> Void) throws -> Void) throws -> R {
        guard let timeout else {
            return try Self.sync(action).get()
        }
        
        @Atomic var result: Result<R, Error>!
        guard try Self.sync(action, $result).wait(timeout: .now() + timeout) == .success else {
            throw CommonError.timedOut(what: name ?? "Async-to-sync operation")
        }
        return try result.get()
    }
    
    public func sync(_ action: (@escaping (Error?) -> Void) throws -> Void) throws {
        try sync { (reply: @escaping (Result<(), Error>) -> Void) in
            try action {
                if let error = $0 {
                    reply(.failure(error))
                } else {
                    reply(.success(()))
                }
            }
        }
    }
    
    public func sync<T>(_ action: (@escaping (T) -> Void) throws -> Void) throws -> T {
        try sync { (reply: @escaping (Result<T, Error>) -> Void) in
            try action {
                reply(.success($0))
            }
        }
    }
    
    public func sync<R>(_ action: @escaping @Sendable () async throws -> R) throws -> R {
        try sync { completion in
            Task {
                do {
                    let success = try await action()
                    completion(.success(success))
                } catch {
                    completion(.failure(error))
                }
            }
        }
    }
    
    private static func sync<R>(
        _ action: (@escaping @Sendable (R) -> Void) throws -> Void,
        _ result: Atomic<R?>
    ) rethrows -> DispatchGroup {
        let group = DispatchGroup()
        group.enter()
        
        let once = AtomicFlag()
        try action {
            guard !once.testAndSet() else {
                if !RunEnvironment.isXCTesting {
                    assertionFailure("\(Self.self) async action called multiple times")
                }
                return
            }
            result.wrappedValue = $0
            group.leave()
        }
        
        return group
    }
}

extension SynchronousExecutor {
    public static func sync<R>(_ action: (@escaping @Sendable (R) -> Void) throws -> Void) rethrows -> R {
        @Atomic var result: R!
        try sync(action, $result).wait()
        return result
    }
    
    public static func sync<R>(_ action: @escaping @Sendable () async -> R) -> R {
        sync { completion in
            Task {
                let result = await action()
                completion(result)
            }
        }
    }
}
