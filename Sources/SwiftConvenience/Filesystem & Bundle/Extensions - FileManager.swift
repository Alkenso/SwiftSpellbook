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
}

extension stat {
    public var fileType: FileManager.FileType? {
        FileManager.FileType(mode: st_mode)
    }
}

extension FileManager {
    public enum FileType {
        case blockSpecial
        case characterSpecial
        case fifo
        case regular
        case directory
        case symbolicLink
        case socket
    }
}

extension FileManager.FileType {
    public init?(mode: mode_t) {
        switch mode & S_IFMT {
        case S_IFBLK: self = .blockSpecial
        case S_IFCHR: self = .characterSpecial
        case S_IFDIR: self = .directory
        case S_IFIFO: self = .fifo
        case S_IFLNK: self = .symbolicLink
        case S_IFREG: self = .regular
        case S_IFSOCK: self = .socket
        default: return nil
        }
    }
}
