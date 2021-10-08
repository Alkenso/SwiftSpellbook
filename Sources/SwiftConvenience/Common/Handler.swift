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
public struct Handler<T, R>: HandlerProtocol {
    private let action: (T) -> R
    
    
    public init(_ action: @escaping (T) -> R) {
        self.action = action
    }
    
    public func callAsFunction(_ value: T) -> R {
        action(value)
    }
}


public protocol HandlerProtocol {
    associatedtype T
    associatedtype R
    
    init(_ handler: @escaping (T) -> R)
    
    func callAsFunction(_ value: T) -> R
}

extension HandlerProtocol {
    /// Converts handler into usual closure, keeping all wraps
    public var asClosure: (T) -> R { callAsFunction }
    
    ///
    public func sync(on queue: DispatchQueue) -> Self {
        Self { result in queue.sync { self(result) } }
    }
}

extension HandlerProtocol where R == Void {
    public var oneShot: Self {
        var once = atomic_flag()
        return Self { result in
            once.callOnce { self(result) }
        }
    }
    
    public func async(on queue: DispatchQueue) -> Self {
        Self { result in queue.async { self(result) } }
    }
}

extension HandlerProtocol where T == Void {
    public func execute() -> R { self(()) }
}

extension HandlerProtocol {
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

