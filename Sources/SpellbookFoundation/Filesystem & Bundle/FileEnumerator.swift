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
    private var enumerator: FileManager.DirectoryEnumerator?
    
    /// If not empty, only specified URL types will be enumerated.
    public var types: Set<URLFileResourceType> = []
    
    /// If set, the filter is applied to every URL while enumeration.
    public var locationFilter: ((URL) -> FilterVerdict)?
    
    /// Forward flags to underlying `FileManager.DirectoryEnumerator`.
    public var options: (URL) -> FileManager.DirectoryEnumerationOptions = { _ in [] }
    
    /// Creates `FileEnumerator` that enumerates given locations recursively
    /// - Parameters:
    ///     - types: In not empty, set of file types, included into enumeration
    ///     - locations: Array of locations enumerated recursively
    public init(types: Set<URLFileResourceType> = [], locations: [URL]) {
        self.locations = locations.reversed()
        self.types = types
    }
}

extension FileEnumerator {
    public struct FilterVerdict: Sendable {
        public var current: Bool
        public var children: Bool
        
        public init(current: Bool, children: Bool) {
            self.current = current
            self.children = children
        }
        
        /// URL is included into results.
        public static let proceed = Self(current: true, children: true)
        
        /// URL is excluded from results.
        public static let skip = Self(current: false, children: true)
        
        /// URL and all descendants are excluded from results.
        public static let skipRecursive = Self(current: false, children: false)
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

extension FileEnumerator: Sequence, IteratorProtocol {
    public func next() -> URL? {
        while let next = nextUnfiltered() {
            let type = try? next.resourceValues(forKeys: [.fileResourceTypeKey]).fileResourceType
            var filterVerdict: FilterVerdict?
            
            // If directory is not interested, skip whole content.
            if type == .directory {
                filterVerdict = locationFilter?(next)
                if filterVerdict?.children == false {
                    enumerator?.skipDescendants()
                }
            }
            
            // Check if `next` is interested according to its type.
            if !types.isEmpty {
                guard let type else { continue }
                guard types.contains(type) else { continue }
            }
            
            // Check if `next` is interested according to its URL.
            if let verdict = filterVerdict ?? locationFilter?(next), !verdict.current {
                continue
            }
            
            return next
        }
        
        return nil
    }
    
    private func nextUnfiltered() -> URL? {
        // If next file exists, just return it.
        if let next = enumerator?.nextObject() as? URL {
            return next
        }
        
        // All files/locations enumerated. 'nil' means the end of the sequence.
        guard let nextLocation = locations.popLast() else {
            return nil
        }
        
        // If location doesn't exists, just skip it.
        var isDirectory = false
        guard FileManager.default.fileExists(at: nextLocation, isDirectory: &isDirectory) else {
            return nextUnfiltered()
        }
        
        // If location is directory, update enumerator.
        if isDirectory {
            enumerator = FileManager.default.enumerator(
                at: nextLocation,
                includingPropertiesForKeys: [.fileResourceTypeKey],
                options: options(nextLocation)
            )
        }
        
        return nextLocation
    }
}
