import Foundation


public extension FileManager {
    func setAttributes(_ attributes: [FileAttributeKey: Any], recursivelyOfItemAt url: URL) throws {
        try self.setAttributes(attributes, ofItemAtPath: url.path)
        guard let enumerator = enumerator(at: url, includingPropertiesForKeys: nil) else { return }
        
        for case let child as URL in enumerator {
            try setAttributes(attributes, ofItemAtPath: child.path)
        }
    }
    
    func directoryExists(at url: URL) -> Bool {
        var isDirectory = ObjCBool(false)
        return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue
    }
    
    func fileExists(at url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.path)
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
        let fm = FileManager.default
        if !fm.fileExists(at: target) && createTarget {
            try fm.createDirectory(at: target, withIntermediateDirectories: true, attributes: nil)
        }
        try fm.contentsOfDirectory(at: src, includingPropertiesForKeys: nil)
            .map { ($0, target.appendingPathComponent($0.lastPathComponent)) }
            .forEach { try fm.copyItem(at: $0, to: $1) }
    }
}
