import Foundation


/// In contrast to NSRegularExpression, implements matching for string by wildcards "*" and "?".
public struct WildcardExpression {
    public var pattern: String
    public var caseSensitive = true
    public var fileNames = true
    
    
    public init(pattern: String, caseSensitive: Bool = true, fileNames: Bool = true) {
        self.pattern = pattern
        self.caseSensitive = caseSensitive
        self.fileNames = fileNames
    }
    
    public init(pattern: String) {
        self.pattern = pattern
    }
    
    public func match(_ string: String) -> Bool {
        string.withCString { string in
            pattern.withCString { pattern in
                fnmatch(pattern, string, flags) == 0
            }
        }
    }
    
    private var flags: Int32 {
        var flags: Int32 = 0
        if caseSensitive {
            flags = flags | FNM_CASEFOLD
        }
        if fileNames {
            flags = flags | FNM_FILE_NAME
        }
        return flags
    }
}
