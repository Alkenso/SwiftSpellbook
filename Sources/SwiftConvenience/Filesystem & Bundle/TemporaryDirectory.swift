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

public struct TemporaryDirectory {
    public let url: URL
    
    public static var `default`: TemporaryDirectory {
        .init(url: URL(fileURLWithPath: NSTemporaryDirectory()))
    }
    
    public init(url tempDir: URL) {
        url = tempDir
    }
    
    public func createDirectoryTree(includingLastPathComponent: Bool = true) throws {
        var createURL = url
        if !includingLastPathComponent {
            createURL.deleteLastPathComponent()
        }
        if !FileManager.default.directoryExists(at: createURL) {
            try FileManager.default.createDirectory(at: createURL, withIntermediateDirectories: true, attributes: nil)
        }
    }
    
    public func subdir(_ subdir: String) -> TemporaryDirectory {
        TemporaryDirectory(
            url: url
                .appendingPathComponent(subdir, isDirectory: true)
                .standardizedFileURL
        )
    }
    
    public func file(_ name: String) -> URL {
        url.appendingPathComponent(name, isDirectory: false).standardizedFileURL
    }
    
    /// Creates unique location at system temporary directory.
    /// Does NOT create anything at that location.
    public func uniqueSubdir(prefix: String? = nil) -> TemporaryDirectory {
        let name = (prefix.flatMap { "\($0)-" } ?? "") + UUID().uuidString
        return TemporaryDirectory(
            url: url
                .appendingPathComponent(name, isDirectory: true)
                .standardizedFileURL
        )
    }
    
    /// Creates unique location at system temporary directory by adding unique extension to the basename.
    /// Does NOT create anything at that location.
    public func uniqueFile(basename: String) -> URL {
        url.appendingPathComponent(basename)
            .appendingPathExtension(UUID().uuidString)
            .standardizedFileURL
    }
    
    /// Creates unique location at system temporary directory.
    /// Does NOT create anything at that location.
    public func uniqueFile(prefix: String? = nil) -> URL {
        let name = (prefix.flatMap { "\($0)-" } ?? "") + UUID().uuidString
        return url.appendingPathComponent(name).standardizedFileURL
    }
}
