import Foundation


public extension stat {
    init?(_ url: URL) {
        var st = stat()
        guard url.withUnsafeFileSystemRepresentation({ stat($0, &st) }) == 0 else { return nil }
        self = st
    }
}
