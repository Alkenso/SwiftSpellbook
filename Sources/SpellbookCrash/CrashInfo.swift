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

public struct CrashInfo: BitwiseCopyable {
    public var version: UInt32
    public var _padding1: UInt32
    public var message: UnsafeMutablePointer<CChar>?
    public var signature: UnsafeMutablePointer<CChar>?
    public var backtrace: UnsafeMutablePointer<CChar>?
    public var message2: UnsafeMutablePointer<CChar>?
    public var reserved1: UnsafeMutableRawPointer?
    public var reserved2: UnsafeMutableRawPointer?
    public var reserved3: UnsafeMutableRawPointer?
    
    public nonisolated(unsafe) static let shared = withUnsafeMutablePointer(to: &crashInfoStorage) {
        $0.withMemoryRebound(to: CrashInfo.self, capacity: 1) { $0 }
    }
}

#if swift(>=6.3)
@section("__DATA_DIRTY,__crash_info")
@used
#else
@_section("__DATA_DIRTY,__crash_info")
@_used
#endif
private nonisolated(unsafe) var crashInfoStorage: (
    UInt32, UInt32, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64
) = (5,0,0,0,0,0,0,0,0)
