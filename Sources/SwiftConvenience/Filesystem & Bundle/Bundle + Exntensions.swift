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


extension Bundle {
    /// Bundle name. Value for Info.plist key "CFBundleNameKey".
    public var name: String? { return value(for: kCFBundleNameKey as String) }

    /// Bundle short version. Value for Info.plist key "CFBundleShortVersionString".
    public var shortVersion: String? { return value(for: "CFBundleShortVersionString") }

    /// Bundle version. Value for Info.plist key "CFBundleVersion".
    public var version: String? { return value(for: "CFBundleVersion") }

    private func value(for key: String) -> String? {
        return object(forInfoDictionaryKey: key) as? String
    }
}

extension Bundle {
    /// Searches for given resource inside the bundle and checks if the file exists.
    /// Equivalent to Bundle::url(forResource:withExtension) + FileManager::fileExists.
    /// - throws: NSError with code NSURLErrorFileDoesNotExist, domain NSURLErrorDomain if file does not exist.
    public func existingURL(forResource name: String, withExtension ext: String?) throws -> URL {
        guard let url = url(forResource: name, withExtension: ext),
              FileManager.default.fileExists(atPath: url.path)
        else {
            throw NSError(
                domain: NSURLErrorDomain,
                code: NSURLErrorFileDoesNotExist,
                userInfo: [
                    NSDebugDescriptionErrorKey: "Resource file \(name) not found."
                ]
            )
        }
        
        return url
    }
}
