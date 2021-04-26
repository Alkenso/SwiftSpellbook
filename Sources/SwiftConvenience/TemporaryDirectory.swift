import Foundation


public struct TemporaryFile {
    public let url: URL
    
    public func createDirectoryTree() throws {
        let directory = url.deletingLastPathComponent()
        if !FileManager.default.directoryExists(at: directory) {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
        }
    }
}

public struct TemporaryDirectory {
    public let url: URL
    
    
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
    
    public func file(_ name: String) -> TemporaryFile {
        TemporaryFile(
            url: url
                .appendingPathComponent(name, isDirectory: false)
                .standardizedFileURL
        )
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
    
    /// Creates unique location at system temporary directory by adding unique extension to the name.
    /// Does NOT create anything at that location.
    public func uniqueFile(name: String) -> TemporaryFile {
        return TemporaryFile(
            url: url
                .appendingPathComponent(name)
                .appendingPathExtension(UUID().uuidString)
                .standardizedFileURL
        )
    }
    
    /// Creates unique location at system temporary directory.
    /// Does NOT create anything at that location.
    public func uniqueFile(prefix: String? = nil) -> TemporaryFile {
        let name = (prefix.flatMap { "\($0)-" } ?? "") + UUID().uuidString
        return TemporaryFile(
            url: url
                .appendingPathComponent(name)
                .standardizedFileURL
        )
    }
}

public extension TemporaryDirectory {
    init() {
        url = URL(fileURLWithPath: NSTemporaryDirectory())
    }
}
