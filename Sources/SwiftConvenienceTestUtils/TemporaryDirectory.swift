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
