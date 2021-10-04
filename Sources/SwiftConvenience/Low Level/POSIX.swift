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


extension stat {
    /// Stat the file at given URL path.
    public init(url: URL) throws {
        var st = stat()
        try Self.throwIfError(path: url.path) { url.withUnsafeFileSystemRepresentation { stat($0, &st) } }
        self = st
    }
    
    /// Stat the file at given path.
    public init(path: String) throws {
        var st = stat()
        try Self.throwIfError(path: path) { path.withCString { stat($0, &st) } }
        self = st
    }
    
    private static func throwIfError(path: String, _ body: () -> Int32) throws {
        let ret = body()
        if ret != 0 {
            throw NSError(
                domain: NSPOSIXErrorDomain,
                code: Int(ret),
                userInfo: [
                    NSDebugDescriptionErrorKey: "stat failed. code = \(ret), path = \(path)"
                ]
            )
        }
    }
}
