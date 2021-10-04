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


extension FileManager {
    /// Sets the attributes of the specified file or directory recursively.
    public func setAttributes(_ attributes: [FileAttributeKey: Any], recursivelyOfItemAt url: URL) throws {
        try FileEnumerator(locations: [url])
            .forEach { try setAttributes(attributes, ofItemAtPath: $0.path) }
    }
    
    /// Returns a Boolean value that indicates whether a url is directory and it exists.
    public func directoryExists(at url: URL) -> Bool {
        var isDirectory = false
        return fileExists(at: url, isDirectory: &isDirectory) && isDirectory
    }
    
    /// Creates all missing intermediate directories for a given file.
    public func createDirectoryTree(for file: URL, attributes: [FileAttributeKey: Any]? = nil) throws {
        let directory = file.deletingLastPathComponent()
        if !FileManager.default.directoryExists(at: directory) {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: attributes)
        }
    }
    
    /// Returns a Boolean value that indicates whether filesystem item at url exists.
    public func fileExists(at url: URL) -> Bool {
        var isDirectory = false
        return fileExists(at: url, isDirectory: &isDirectory)
    }
    
    /// Returns a Boolean value that indicates whether a file or directory exists at a specified url.
    public func fileExists(at url: URL, isDirectory: inout Bool) -> Bool {
        var isDirectoryObjc = ObjCBool(false)
        let exists = fileExists(atPath: url.path, isDirectory: &isDirectoryObjc)
        isDirectory = isDirectoryObjc.boolValue
        return exists
    }
    
    /// Copies contents of given directory to other directory.
    public func copyContents(ofDirectory src: URL, to target: URL, createTarget: Bool = false) throws {
        if !fileExists(at: target) && createTarget {
            try createDirectory(at: target, withIntermediateDirectories: true, attributes: nil)
        }
        try contentsOfDirectory(at: src, includingPropertiesForKeys: nil)
            .map { ($0, target.appendingPathComponent($0.lastPathComponent)) }
            .forEach { try copyItem(at: $0, to: $1) }
    }
}
