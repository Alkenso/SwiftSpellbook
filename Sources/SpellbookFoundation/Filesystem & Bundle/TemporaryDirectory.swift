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

/// A convenient interface to deal with temporary directories.
public struct TemporaryDirectory {
    public let location: URL
    
    /// Initializes temporary directory with given location.
    public init(at location: URL) {
        self.location = location
    }
    
    /// Initializes temporarty directory inside current user temporary directory with given prefix and name.
    /// - Parameters:
    ///   - prefix: if specified, prefixes the name of new directory.
    ///   - name: if specified, acts like the name of new directory. Otherwise `UUID` is used.
    public init(prefix: String? = nil, name: String? = nil) {
        self = TemporaryDirectory(at: URL(fileURLWithPath: NSTemporaryDirectory()))
            .directory(prefix: prefix, name: name)
    }
    
    /// Creates a directory with the given attributes at the specified URL.
    /// Does nothing if the directory already exists.
    @discardableResult
    public func setUp(attributes: [FileAttributeKey : Any]? = nil) throws -> Self {
        try FileManager.default.createDirectory(
            at: location,
            withIntermediateDirectories: true,
            attributes: attributes
        )
        return self
    }
    
    /// Removes the directory if it exists.
    public func tearDown() throws {
        try FileManager.default.removeItemIfExists(at: location)
    }
}

extension TemporaryDirectory {
    /// Temporarty directory named as the main app bundle inside current user temporary directory.
    public static let bundle = TemporaryDirectory(
        name: Bundle.main.bundleIdentifier ?? Bundle.main.bundlePath.lastPathComponent
    )
}

extension TemporaryDirectory {
    /// Creates nested `TemporaryDirectory` using `prefix` and `name` for proper naming.
    /// New directory is NOT actually created. Use `setUp` to create it.
    /// - Parameters:
    ///   - prefix: if specified, prefixes the name of new directory.
    ///   - name: if specified, acts like the name of new directory. Otherwise `UUID` is used.
    public func directory(prefix: String? = nil, name: String? = nil) -> TemporaryDirectory {
        directory(makeName(prefix: prefix, name: name))
    }
    
    /// Creates nested `TemporaryDirectory` using `prefix` and `name` for proper naming.
    /// New directory is NOT actually created. Use `setUp` to create it.
    /// - Parameters:
    ///   - subpath: path relative to URL of current `TemporaryDirectory`.
    public func directory(_ subpath: String) -> TemporaryDirectory {
        TemporaryDirectory(
            at: location
                .appendingPathComponent(subpath, isDirectory: true)
                .standardizedFileURL
        )
    }
    
    /// Produces URL to nested file using `prefix` and `name` for proper naming.
    /// The file is NOT actually created. Use `createFile` to actually create it.
    /// - Parameters:
    ///   - prefix: if specified, prefixes the name of the file.
    ///   - name: if specified, acts like the name of the file. Otherwise `UUID` is used.
    ///   - extension: if specified, used as extension of the file.
    public func file(prefix: String? = nil, name: String? = nil, extension ext: String? = nil) -> URL {
        let fullName = makeName(prefix: prefix, name: name, extension: ext)
        return location.appendingPathComponent(fullName, isDirectory: false).standardizedFileURL
    }
    
    /// Creates nested file using `prefix` and `name` for proper naming.
    /// If the file already exists, this method will overwrite it.
    /// - Parameters:
    ///   - prefix: if specified, prefixes the name of the file.
    ///   - name: if specified, acts like the name of the file. Otherwise `UUID` is used.
    ///   - extension: if specified, used as extension of the file.
    ///   - content: A data object containing the contents of the new file.
    ///   - attributes: A dictionary containing the attributes to associate with the new file.
    ///   You can use these attributes to set the owner and group numbers, file permissions, and modification date.
    ///   For a list of keys, see `FileAttributeKey`. 
    ///   If you specify `nil` for attributes, the file is created with a set of default attributes.
    public func createFile(
        prefix: String? = nil,
        name: String? = nil,
        extension ext: String? = nil,
        content: Data,
        attributes: [FileAttributeKey : Any]? = nil
    ) throws -> URL {
        let file = file(prefix: prefix, name: name, extension: ext)
        guard FileManager.default.createFile(atPath: file.path, contents: content, attributes: attributes) else {
            throw URLError(.cannotWriteToFile, userInfo: [NSFilePathErrorKey: file.path])
        }
        return file
    }
    
    private func makeName(prefix: String?, name: String?, extension ext: String? = nil) -> String {
        var fullName = name ?? UUID().uuidString
        if let prefix {
            fullName = prefix + fullName
        }
        if let ext {
            fullName = fullName.appendingPathExtension(ext)
        }
        return fullName
    }
}
