import Foundation


public extension FileManager {
    /// Sets the attributes of the specified file or directory recursively.
    func setAttributes(_ attributes: [FileAttributeKey: Any], recursivelyOfItemAt url: URL) throws {
        try FileEnumerator(locations: [url])
            .forEach { try setAttributes(attributes, ofItemAtPath: $0.path) }
    }
    
    /// Returns a Boolean value that indicates whether a url is directory and it exists.
    func directoryExists(at url: URL) -> Bool {
        var isDirectory = false
        return fileExists(at: url, isDirectory: &isDirectory) && isDirectory
    }
    
    /// Returns a Boolean value that indicates whether filesystem item at url exists.
    func fileExists(at url: URL) -> Bool {
        var isDirectory = false
        return fileExists(at: url, isDirectory: &isDirectory)
    }
    
    /// Returns a Boolean value that indicates whether a file or directory exists at a specified url.
    func fileExists(at url: URL, isDirectory: inout Bool) -> Bool {
        var isDirectoryObjc = ObjCBool(false)
        let exists = fileExists(atPath: url.path, isDirectory: &isDirectoryObjc)
        isDirectory = isDirectoryObjc.boolValue
        return exists
    }
    
    /// Creates unique location at system temporary directory.
    /// Does NOT create anything at that location.
    func makeUniqueTempLocation(subfolder: String? = nil, prefix: String? = nil) -> URL {
        let name = prefix.flatMap { "\($0)-" } ?? "" + UUID().uuidString
        return URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(name)
            .appendingPathComponent(subfolder ?? "")
            .standardizedFileURL
    }
    
    /// Copies contents of given directory to other directory.
    func copyContents(ofDirectory src: URL, to target: URL, createTarget: Bool = false) throws {
        if !fileExists(at: target) && createTarget {
            try createDirectory(at: target, withIntermediateDirectories: true, attributes: nil)
        }
        try contentsOfDirectory(at: src, includingPropertiesForKeys: nil)
            .map { ($0, target.appendingPathComponent($0.lastPathComponent)) }
            .forEach { try copyItem(at: $0, to: $1) }
    }
}
