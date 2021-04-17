import Foundation


public extension stat {
    /// Stat the file at given URL path.
    init?(_ url: URL) {
        var st = stat()
        guard url.withUnsafeFileSystemRepresentation({ stat($0, &st) }) == 0 else { return nil }
        self = st
    }
}
