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
    public let body: (T) -> R
    
    public init(_ body: @escaping (T) -> R) {
        self.body = body
    }
    
    public func callAsFunction<each Arg>(_ args: repeat each Arg) -> R where T == (repeat each Arg) {
        body(makeTuple(repeat each args))
    }
}

extension Closure {
    public func oneShot() -> Self where R == Void {
        let once = AtomicFlag()
        return Self { result in
            if !once.testAndSet() {
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

/// Throwing version of `Closure`
public struct ThrowingClosure<T, R> {
    public let body: (T) throws -> R
    
    public init(_ body: @escaping (T) throws -> R) {
        self.body = body
    }
    
    public func callAsFunction<each Arg>(_ args: repeat each Arg) throws -> R where T == (repeat each Arg) {
        try body(makeTuple(repeat each args))
    }
}

extension ThrowingClosure {
    public func oneShot() -> Self where R == Void {
        let once = AtomicFlag()
        return ThrowingClosure { value in
            if !once.testAndSet() {
                try self(value)
            }
        }
    }
    
    public func sync(on queue: DispatchQueue) -> Self {
        ThrowingClosure { value in try queue.sync { try self(value) } }
    }
}

// Workaround to make Swift 5.9/5.10 compilers happy.
private func makeTuple<each Element>(_ element: repeat each Element) -> (repeat each Element) {
    (repeat each element)
}
