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

import Foundation

/// Wrapper around the closure that allows extending.
/// Design follows 'Decorator' pattern.
public struct Closure<T, R> {
    private let action: (T) -> R
    
    public init(_ action: @escaping (T) -> R) {
        self.action = action
    }
    
    public func callAsFunction(_ value: T) -> R {
        action(value)
    }
}

extension Closure {
    /// Converts into usual closure, keeping all wraps
    public var asClosure: (T) -> R { callAsFunction }
}

extension Closure {
    public func oneShot() -> Self where R == Void {
        var once = atomic_flag()
        return Self { result in
            if !atomic_flag_test_and_set(&once) {
                self(result)
            }
        }
    }
    
    public func sync(on queue: DispatchQueue) -> Self {
        Self { result in queue.sync { self(result) } }
    }
    
    public func async(on queue: DispatchQueue) -> Self where R == Void {
        Self { result in queue.async { self(result) } }
    }
}

extension Closure where T == Void {
    public func callAsFunction() -> R { self(()) }
}

extension Closure {
    public func callAsFunction<T1, T2>(_ arg1: T1, _ arg2: T2) -> R where T == (T1, T2) {
        callAsFunction((arg1, arg2))
    }
    
    public func callAsFunction<T1, T2, T3>(_ arg1: T1, _ arg2: T2, _ arg3: T3) -> R where T == (T1, T2, T3) {
        callAsFunction((arg1, arg2, arg3))
    }
    
    public func callAsFunction<T1, T2, T3, T4>(_ arg1: T1, _ arg2: T2, _ arg3: T3, _ arg4: T4) -> R where T == (T1, T2, T3, T4) {
        callAsFunction((arg1, arg2, arg3, arg4))
    }
    
    public func callAsFunction<T1, T2, T3, T4, T5>(_ arg1: T1, _ arg2: T2, _ arg3: T3, _ arg4: T4, _ arg5: T5) -> R where T == (T1, T2, T3, T4, T5) {
        callAsFunction((arg1, arg2, arg3, arg4, arg5))
    }
    
    public func callAsFunction<T1, T2, T3, T4, T5, T6>(_ arg1: T1, _ arg2: T2, _ arg3: T3, _ arg4: T4, _ arg5: T5, _ arg6: T6) -> R where T == (T1, T2, T3, T4, T5, T6) {
        callAsFunction((arg1, arg2, arg3, arg4, arg5, arg6))
    }
}

/// Throwing version of `Closure`
public struct ClosureT<T, R> {
    private let action: (T) throws -> R
    
    public init(_ action: @escaping (T) throws -> R) {
        self.action = action
    }
    
    public func callAsFunction(_ value: T) throws -> R {
        try action(value)
    }
}

extension ClosureT {
    /// Converts into usual closure, keeping all wraps
    public var asClosure: (T) throws -> R { callAsFunction }
}

extension ClosureT {
    public func oneShot() -> Self where R == Void {
        var once = atomic_flag()
        return Self { value in
            var result: Result<R, Error>?
            if !atomic_flag_test_and_set(&once) {
                result = Result { try self(value) }
            }
            try result?.get()
        }
    }
    
    public func sync(on queue: DispatchQueue) -> Self {
        Self { value in try queue.sync { try self(value) } }
    }
}

extension ClosureT where T == Void {
    public func callAsFunction() throws -> R { try self(()) }
}

extension ClosureT {
    public func callAsFunction<T1, T2>(_ arg1: T1, _ arg2: T2) throws -> R where T == (T1, T2) {
        try callAsFunction((arg1, arg2))
    }
    
    public func callAsFunction<T1, T2, T3>(_ arg1: T1, _ arg2: T2, _ arg3: T3) throws -> R where T == (T1, T2, T3) {
        try callAsFunction((arg1, arg2, arg3))
    }
    
    public func callAsFunction<T1, T2, T3, T4>(_ arg1: T1, _ arg2: T2, _ arg3: T3, _ arg4: T4) throws -> R where T == (T1, T2, T3, T4) {
        try callAsFunction((arg1, arg2, arg3, arg4))
    }
    
    public func callAsFunction<T1, T2, T3, T4, T5>(_ arg1: T1, _ arg2: T2, _ arg3: T3, _ arg4: T4, _ arg5: T5) throws -> R where T == (T1, T2, T3, T4, T5) {
        try callAsFunction((arg1, arg2, arg3, arg4, arg5))
    }
    
    public func callAsFunction<T1, T2, T3, T4, T5, T6>(_ arg1: T1, _ arg2: T2, _ arg3: T3, _ arg4: T4, _ arg5: T5, _ arg6: T6) throws -> R where T == (T1, T2, T3, T4, T5, T6) {
        try callAsFunction((arg1, arg2, arg3, arg4, arg5, arg6))
    }
}
