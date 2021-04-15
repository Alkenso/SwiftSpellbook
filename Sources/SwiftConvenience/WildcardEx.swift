import Foundation


public struct WildcardEx {
    public var pattern: String
    public var caseSensitive = true
    public var fileNames = true
    
    
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
