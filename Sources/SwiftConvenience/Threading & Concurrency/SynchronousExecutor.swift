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

/// Executes synchronously the asynchronous method with completion handler.
/// - Note: While this is not the best practice ever,
///         real-world tasks time to time require exactly this.
public struct SynchronousExecutor {
    public var name: String?
    public var timeout: TimeInterval?
    
    public init(_ name: String? = nil, timeout: TimeInterval?) {
        self.name = name
        self.timeout = timeout
    }
    
    public func callAsFunction<R>(_ action: (@escaping (Result<R, Error>) -> Void) throws -> Void) throws -> R {
        @Atomic var result: Result<R, Error>!
        let group = DispatchGroup()
        group.enter()
        
        var once = atomic_flag()
        try action {
            guard !atomic_flag_test_and_set(&once) else { return }
            result = $0
            group.leave()
        }
        
        if let timeout {
            guard group.wait(timeout: .now() + timeout) == .success else {
                throw CommonError.timedOut(what: name ?? "Operation")
            }
        } else {
            group.wait()
        }
        
        return try result.get()
    }
}

extension SynchronousExecutor {
    public func callAsFunction(_ action: (@escaping (Error?) -> Void) throws -> Void) throws {
        try callAsFunction { (reply: @escaping (Result<(), Error>) -> Void) in
            try action {
                if let error = $0 {
                    reply(.failure(error))
                } else {
                    reply(.success(()))
                }
            }
        }
    }
    
    public func callAsFunction<T>(_ action: (@escaping (T) -> Void) throws -> Void) throws -> T {
        try callAsFunction { (reply: @escaping (Result<T, Error>) -> Void) in
            try action {
                reply(.success($0))
            }
        }
    }
}
