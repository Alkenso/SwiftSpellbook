//  MIT License
//
//  Copyright (c) 2023 Alkenso (Vladimir Vashurkin)
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

public enum Benchmark {
    /// Executes the given block and returns the number of seconds
    /// with nanosecond precision it takes to execute the block.
    /// This function is for debugging and performance analysis work.
    public static func measure<R>(execute: () throws -> R) rethrows -> (R, TimeInterval) {
        let start = DispatchTime.now()
        let result = try execute()
        let end = DispatchTime.now()
        
        let durationNs = end.uptimeNanoseconds - start.uptimeNanoseconds
        let durationSec = TimeInterval(durationNs) / TimeInterval(NSEC_PER_SEC)
        
        return (result, durationSec)
    }
    
    /// Executes the given block and prints the `name` and the number of seconds
    /// with nanosecond precision it takes to execute the block.
    /// This function is for debugging and performance analysis work.
    public static func measure<R>(_ name: String, execute: () throws -> R) rethrows -> R {
        let (result, durationSec) = try measure(execute: execute)
        print("\(name) takes \(durationSec) sec")
        
        return result
    }
}
