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

extension Error {
    public func `throw`() throws -> Never {
        throw self
    }
}

extension Error {
    /// Not all `Error` objects are NSSecureCoding-compilant.
    /// Such incompatible errors cause raising of NSException during encoding or decoding, especially in XPC messages.
    /// To avoid this, the method perform manual type-check and converting incompatible errors
    /// into most close-to-original but compatible form.
    public func secureCodingCompatible() -> Error {
        let nsError = self as NSError
        guard (try? NSKeyedArchiver.archivedData(withRootObject: nsError, requiringSecureCoding: true)) == nil else {
            return self
        }
        
        let compatibleError = NSError(
            domain: nsError.domain,
            code: nsError.code,
            userInfo: nsError.userInfo.mapValues {
                if $0 is NSSecureCoding { $0 } else { String(describing: $0) }
            }
        )
        return compatibleError
    }
}
