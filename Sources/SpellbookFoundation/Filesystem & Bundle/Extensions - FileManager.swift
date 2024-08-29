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
    
    /// Removes the file or directory at the specified URL only if it exists.
    /// Just combination of `fileExists` and `removeItem`.
    public func removeItemIfExists(at url: URL) throws {
        if fileExists(at: url) {
            try removeItem(at: url)
        }
    }
    
    /// Removes the file or directory at the specified path only if it exists.
    /// Just combination of `fileExists` and `removeItem`.
    public func removeItemIfExists(atPath path: String) throws {
        if fileExists(atPath: path) {
            try removeItem(atPath: path)
        }
    }
    
    /// stat file at given URL
    /// - Parameters:
    ///     - url: URL to stat
    ///     - followSymlinks: if true, stat is used, otherwise lstat
    /// - returns: 'stat' structure
    /// - throws: if URL is not a file URL or file can't be stat'ed
    public func statItem(at url: URL, followSymlinks: Bool = true) throws -> stat {
        try url.ensureFileURL()
        return try statItem(atPath: url.path, followSymlinks: followSymlinks)
    }
    
    /// stat file at given path
    /// - Parameters:
    ///     - url: path to stat
    ///     - followSymlinks: if true, stat is used, otherwise lstat
    /// - returns: 'stat' structure
    /// - throws: if file can't be stat'ed
    public func statItem(atPath path: String, followSymlinks: Bool = true) throws -> stat {
        var st = stat()
        try NSError.posix
            .debugDescription("\(followSymlinks ? "stat" : "lstat") failed")
            .userInfo(path, for: NSFilePathErrorKey)
            .try(path.withCString { followSymlinks ? stat($0, &st) : lstat($0, &st) } == 0)
        return st
    }
    
    public func xattr(at url: URL, name: String) throws -> Data {
        try url.ensureFileURL()
        return try xattr(atPath: url.path, name: name)
    }
    
    public func xattr(atPath path: String, name: String) throws -> Data {
        try NSError.posix.debugDescription("getxattr").try {
            let length = getxattr(path, name, nil, 0, 0, 0)
            guard length >= 0 else { return nil }
            guard length > 0 else { return Data() }
            
            var data = Data(count: length)
            let result = data.withUnsafeMutableBytes { [count = data.count] in
                getxattr(path, name, $0.baseAddress, count, 0, 0)
            }
            
            return result > 0 ? data : nil
        }
    }
    
    public func listXattr(atPath path: String) throws -> [String] {
        try NSError.posix.debugDescription("listxattr").try {
            let length = listxattr(path, nil, 0, 0)
            guard length >= 0 else { return nil }
            guard length > 0 else { return [] }
            
            var data = Data(count: length)
            let result = data.withUnsafeMutableBytes { [count = data.count] in
                listxattr(path, $0.bindMemory(to: CChar.self).baseAddress, count, 0)
            }
            
            guard result > 0 else { return nil }
            return data.split(separator: 0).filter { !$0.isEmpty }.compactMap { String(data: $0, encoding: .utf8) }
        }
    }
    
    public func listXattr(at url: URL) throws -> [String] {
        try url.ensureFileURL()
        return try listXattr(atPath: url.path)
    }
    
    public func setXattr(atPath path: String, name: String, value: Data) throws {
        try NSError.posix.debugDescription("setxattr").try(
            value.withUnsafeBytes { setxattr(path, name, $0.baseAddress, $0.count, 0, 0) >= 0 }
        )
    }
    
    public func setXattr(at url: URL, name: String, value: Data) throws {
        try url.ensureFileURL()
        return try setXattr(atPath: url.path, name: name, value: value)
    }
    
    public func removeXattr(atPath path: String, name: String) throws {
        try NSError.posix.debugDescription("removexattr").try(removexattr(path, name, 0) >= 0)
    }
    
    public func removeXattr(at url: URL, name: String) throws {
        try url.ensureFileURL()
        try removeXattr(atPath: url.path, name: name)
    }
}

extension stat {
    public var fileType: URLFileResourceType {
        URLFileResourceType(mode: st_mode)
    }
}

extension URLFileResourceType {
    public init(mode: mode_t) {
        switch mode & S_IFMT {
        case S_IFBLK: self = .blockSpecial
        case S_IFCHR: self = .characterSpecial
        case S_IFDIR: self = .directory
        case S_IFIFO: self = .namedPipe
        case S_IFLNK: self = .symbolicLink
        case S_IFREG: self = .regular
        case S_IFSOCK: self = .socket
        default: self = .unknown
        }
    }
}
