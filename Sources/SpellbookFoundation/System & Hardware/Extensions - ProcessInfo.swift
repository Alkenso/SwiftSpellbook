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

#if os(macOS)

extension ProcessInfo {
    public static func signingInfo(atPath path: String) throws -> [String: Any] {
        try signingInfo(at: URL(fileURLWithPath: path))
    }
    
    public static func signingInfo(at url: URL) throws -> [String: Any] {
        let code = try NSError.osstatus.try { SecStaticCodeCreateWithPath(url as CFURL, [], $0) }
        let signingInfoCF = try NSError.osstatus.try {
            SecCodeCopySigningInformation(code, SecCSFlags(rawValue: kSecCSSigningInformation), $0)
        }
        guard let signingInfo = signingInfoCF as? [String: Any] else {
            throw CommonError.cast(
                signingInfoCF,
                to: [String: Any].self,
                description: "Invalid SecCodeCopySigningInformation format"
            )
        }
        return signingInfo
    }
    
    public func signingInfo() throws -> [String: Any] {
        try Self.signingInfo(atPath: arguments.first ?? "")
    }
}

#endif
