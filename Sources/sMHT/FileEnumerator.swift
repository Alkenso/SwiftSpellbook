import Foundation


public class FileEnumerator {
    private var locations: [URL]
    private var enumerator: NSEnumerator?
    
    public var filter: Filter?
    
    
    public init(locations: [URL], filter: Filter? = nil) {
        self.locations = locations
        self.filter = filter
    }
}

public extension FileEnumerator {
    enum Filter {
        case function(_ isIncluded: (URL) -> Bool)
        case types(Set<URL.FileType>)
    }
}

extension FileEnumerator: Sequence, IteratorProtocol {
    public func next() -> URL? {
        while let next = nextUnfiltered() {
            guard let filter = filter else { return next }
            if filter(isIncluded: next) {
                return next
            }
        }
        
        return nil
    }
    
    private func nextUnfiltered() -> URL? {
        //  If next file exists, just return it.
        if let next = enumerator?.nextObject() as? URL {
            return next
        }
        
        //  All files/locations enumerated. 'nil' means the end of sequence.
        guard let nextLocation = locations.popLast() else {
            return nil
        }
        
        //  If location doesn't exists, just skip it.
        var isDirectory = ObjCBool(false)
        guard FileManager.default.fileExists(atPath: nextLocation.path, isDirectory: &isDirectory) else {
            return nextUnfiltered()
        }
        
        //  If location is directory, update enumerator.
        if isDirectory.boolValue {
            enumerator = FileManager.default.enumerator(at: nextLocation, includingPropertiesForKeys: nil)
        }
        
        return nextLocation
    }
}

private extension FileEnumerator.Filter {
    func callAsFunction(isIncluded url: URL) -> Bool {
        switch self {
        case .function(let isIncluded):
            return isIncluded(url)
            
        case .types(let types):
            guard let fileType = url.fileType else { return false }
            return types.contains(fileType)
        }
    }
}
