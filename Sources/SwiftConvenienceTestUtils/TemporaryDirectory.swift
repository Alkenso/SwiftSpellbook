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

import SwiftConvenience

import Foundation


public class TestTemporaryDirectory {
    private let _temp: TemporaryDirectory
    public var url: URL { _temp.url }
    

    public init(prefix: String? = nil) {
        _temp = TemporaryDirectory().uniqueSubdir(prefix: prefix)
    }
    
    public func setUp() throws {
        do {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: false)
        } catch {
            throw TestError("Failed to create test directory at \(url).", underlying: error)
        }
    }
    
    public func tearDown() throws {
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            throw TestError("Failed to delete test directory at \(url).", underlying: error)
        }
    }
    
    public func createSubdirectory(_ subpath: String) throws -> URL {
        precondition(!subpath.isEmpty)
        
        let subdirectory = _temp.subdir(subpath).url
        if !FileManager.default.fileExists(atPath: subdirectory.path) {
            try FileManager.default.createDirectory(at: subdirectory, withIntermediateDirectories: true)
        }
        
        return subdirectory
    }
    
    public func createUniqueSubdirectory(prefix: String? = nil) throws -> URL {
        let directory = _temp.uniqueSubdir(prefix: prefix).url
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
    
    public func createFile(_ name: String, content: Data = Data()) throws -> URL {
        precondition(!name.isEmpty)
        
        let file = url.appendingPathComponent(name, isDirectory: false)
        try content.write(to: file, options: [.withoutOverwriting])
        
        return file
    }
    
    public func copyFile(from location: URL) throws -> URL {
        precondition(FileManager.default.fileExists(atPath: url.path))
        
        let file = url.appendingPathComponent(location.lastPathComponent)
        try FileManager.default.copyItem(at: location, to: file)
        
        return file
    }
}
