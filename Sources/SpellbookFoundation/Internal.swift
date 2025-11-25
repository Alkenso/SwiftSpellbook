//  MIT License
//
//  Copyright (c) 2024 Alkenso (Vladimir Vashurkin)
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

extension Optional where Wrapped == DispatchQueue {
    @inline(__always)
    package func async(flags: DispatchWorkItemFlags = [], execute work: @escaping () -> Void) {
        if let self {
            nonisolated(unsafe) let work = work
            self.async(flags: flags) { work() }
        } else {
            work()
        }
    }
    
    @inline(__always)
    package func sync<R>(execute work: () -> R) -> R {
        if let self {
            return self.sync(execute: work)
        } else {
            return work()
        }
    }
}

/// Use with care only in functions that don't `rethrow` but `throws(E)`.
@usableFromInline
internal func _typedRethrow<R, E: Error>(error: E.Type, _ body: () throws -> R) throws(E) -> R {
    do {
        return try body()
    } catch {
        throw error as! E
    }
}
