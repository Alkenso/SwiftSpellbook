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

/// In contrast to NSRegularExpression, implements matching for string by wildcards `*` and `?`.
/// `WildcardExpression` is Swift wrapper around `fnmatch` function.
public struct WildcardExpression {
    public var pattern: String
    public var caseSensitive: Bool
    
    /// Slash characters in string must be explicitly matched by slashes in pattern.
    /// If this flag is not set, then slashes are treated as regular characters.
    public var fileNames: Bool
    
    public init(pattern: String, caseSensitive: Bool = true, fileNames: Bool = false) {
        self.pattern = pattern
        self.caseSensitive = caseSensitive
        self.fileNames = fileNames
    }
    
    public func match(_ string: String) -> Bool {
        string.withCString { string in
            pattern.withCString { pattern in
                fnmatch(pattern, string, flags) == 0
            }
        }
    }
    
    private var flags: Int32 {
        var flags: Int32 = 0
        if !caseSensitive {
            flags |= FNM_CASEFOLD
        }
        if fileNames {
            flags |= FNM_FILE_NAME
        }
        return flags
    }
}

extension WildcardExpression {
    public static func caseSensitive(pattern: String) -> Self {
        .init(pattern: pattern, caseSensitive: true)
    }
    
    public static func caseInsensitive(pattern: String) -> Self {
        .init(pattern: pattern, caseSensitive: false)
    }
}
