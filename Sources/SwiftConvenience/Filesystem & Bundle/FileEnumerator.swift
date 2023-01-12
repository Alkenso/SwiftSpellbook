//  MIT License
//
//  Copyright (c) 2021 Alkenso (Vladimir Vashurkin)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import Foundation

/// Performs convenient enumeration of filesystem items at given location(s).
public final class FileEnumerator {
    private var locations: [URL]
    private var enumerator: NSEnumerator?
    
    public var filters: [Filter] = []
    public var options: FileManager.DirectoryEnumerationOptions = []
    
    /// Creates `FileEnumerator` that enumerates given locations recursively
    /// - Parameters:
    ///     - types: In not empty, set of file types, included into enumeration
    ///     - locations: Array of locations enumerated recursively
    public init(types: Set<URLFileResourceType> = [], locations: [URL]) {
        self.locations = locations.reversed()
        if !types.isEmpty {
            filters.append(.types(types))
        }
    }
}

extension FileEnumerator {
    /// Creates `FileEnumerator` that enumerates given location
    /// - Parameters:
    ///     - types: In not empty, set of file types, included into enumeration
    ///     - locations: Location enumerated recursively
    public convenience init(types: Set<URLFileResourceType> = [], _ location: URL) {
        self.init(types: types, locations: [location])
    }
    
    /// Creates `FileEnumerator` that enumerates given file paths recursively
    /// - Parameters:
    ///     - types: In not empty, set of file types, included into enumeration
    ///     - paths: Array of file paths enumerated recursively
    public convenience init(types: Set<URLFileResourceType> = [], paths: [String]) {
        self.init(types: types, locations: paths.map(URL.init(fileURLWithPath:)))
    }
    
    /// Creates `FileEnumerator` that enumerates given file path recursively
    /// - Parameters:
    ///     - types: In not empty, set of file types, included into enumeration
    ///     - paths: File path enumerated recursively
    public convenience init(types: Set<URLFileResourceType> = [], _ path: String) {
        self.init(types: types, paths: [path])
    }
}

extension FileEnumerator {
    public enum Filter {
        case function(_ isIncluded: (URL) -> Bool)
        case types(Set<URLFileResourceType>)
    }
}

extension FileEnumerator: Sequence, IteratorProtocol {
    public func next() -> URL? {
        guard !filters.isEmpty else { return nextUnfiltered() }
        
        while let next = nextUnfiltered() {
            let excluded = filters.contains(where: { !$0(isIncluded: next) })
            if !excluded {
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
        
        //  All files/locations enumerated. 'nil' means the end of the sequence.
        guard let nextLocation = locations.popLast() else {
            return nil
        }
        
        //  If location doesn't exists, just skip it.
        var isDirectory = false
        guard FileManager.default.fileExists(at: nextLocation, isDirectory: &isDirectory) else {
            return nextUnfiltered()
        }
        
        //  If location is directory, update enumerator.
        if isDirectory {
            enumerator = FileManager.default.enumerator(at: nextLocation, includingPropertiesForKeys: nil, options: options)
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
            guard let fileType = try? FileManager.default.statItem(at: url).fileType else { return false }
            return types.contains(fileType)
        }
    }
}
