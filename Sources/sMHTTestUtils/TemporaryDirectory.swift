import Foundation


public class TestTemporaryDirectory {
    public let url: URL
    

    public init(prefix: String? = nil) {
        let directoryName = Self.makeDirectoryUniqueName(prefix: prefix)
        url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(directoryName)
            .standardizedFileURL
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
    
    public func createSubdirectory(subpath: String) throws -> URL {
        precondition(!subpath.isEmpty)
        
        let subdirectory = url.appendingPathComponent(subpath, isDirectory: true)
        if !FileManager.default.fileExists(atPath: subdirectory.path) {
            try FileManager.default.createDirectory(at: subdirectory, withIntermediateDirectories: true)
        }
        
        return subdirectory
    }
    
    public func createUniqueSubdirectory(prefix: String? = nil) throws -> URL {
        let directoryName = Self.makeDirectoryUniqueName(prefix: prefix)
        return try createSubdirectory(subpath: directoryName)
    }
    
    public func createFile(name: String, contents: Data = Data()) throws -> URL {
        precondition(!name.isEmpty)
        
        let file = url.appendingPathComponent(name, isDirectory: false)
        try contents.write(to: file, options: [.withoutOverwriting])
        
        return file
    }
    
    public func copyFile(from location: URL) throws -> URL {
        precondition(FileManager.default.fileExists(atPath: url.path))
        
        let file = url.appendingPathComponent(location.lastPathComponent)
        try FileManager.default.copyItem(at: location, to: file)
        
        return file
    }
    
    private static func makeDirectoryUniqueName(prefix: String? = nil) -> String {
        prefix.flatMap { "\($0)-" } ?? "" + UUID().uuidString
    }
}
