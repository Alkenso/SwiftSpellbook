//  MIT License
//
//  Copyright (c) 2022 Alkenso (Vladimir Vashurkin)
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

/// Wraps common file operations file reading and writing.
/// Provides ability to change underlying implementation to mock dealing with real file system.
public struct FileStore<T> {
    private let read: (URL, T?) throws -> T
    private let write: (T, URL, Bool) throws -> Void
    
    public init(
        read: @escaping (URL, T?) throws -> T,
        write: @escaping (T, URL, Bool) throws -> Void
    ) {
        self.read = read
        self.write = write
    }
    
    public func read(from location: URL, default ifNotExists: T? = nil) throws -> T {
        try read(location, ifNotExists)
    }
    
    public func write(_ value: T, to location: URL, createDirectories: Bool = false) throws {
        try write(value, location, createDirectories)
    }
}

extension FileStore where T == Data {
    public static var standard = FileStore(
        read: { location, ifNotExists in
            try Data(contentsOf: location, ifNoFile: ifNotExists)
        },
        write: { data, location, createDirectories in
            if createDirectories {
                try FileManager.default.createDirectoryTree(for: location)
            }
            try data.write(to: location)
        }
    )
}

extension FileStore {
    public func synchronized(on queue: DispatchQueue) -> Self {
        .init(
            read: { location, ifNotExists in
                try queue.sync {
                    try self.read(from: location, default: ifNotExists)
                }
            },
            write: { value, location, createDirectories in
                try queue.sync(flags: .barrier) {
                    try self.write(value, to: location, createDirectories: createDirectories)
                }
            }
        )
    }
}

// MARK: - Exact file

extension FileStore {
    public func exact(_ location: URL, default ifNotExists: T? = nil) -> Exact {
        .init(location: location, store: self, ifNotExists: ifNotExists)
    }
    
    public struct Exact {
        public let location: URL
        fileprivate let store: FileStore
        fileprivate let ifNotExists: T?
        
        public func read(default ifNotExistsOverride: T? = nil) throws -> T {
            try store.read(from: location, default: ifNotExistsOverride ?? ifNotExists)
        }
        
        public func write(_ value: T, createDirectories: Bool = false) throws {
            try store.write(value, to: location, createDirectories: createDirectories)
        }
    }
}

// MARK: - Codable

extension FileStore where T == Data {
    private static let nonexistentValue = UUID().uuidString.utf8Data
    
    public func codable<U: Codable>(_ type: U.Type = U.self, using coder: FileStoreCoder<U>) -> FileStore<U> {
        .init(
            read: { try decode(U.self, from: $0, using: coder.decoder, default: $1) },
            write: { try encode($0, to: $1, using: coder.encoder, createDirectories: $2) }
        )
    }
    
    public func encode<U: Encodable>(
        _ value: U,
        to location: URL,
        using encoder: ObjectEncoder<U>,
        createDirectories: Bool = false
    ) throws {
        let data = try encoder.encode(value)
        try write(data, to: location, createDirectories: createDirectories)
    }
    
    public func decode<U: Decodable>(
        _ type: U.Type,
        from location: URL,
        using decoder: ObjectDecoder<U>,
        default ifNotExists: U? = nil
    ) throws -> U {
        let data: Data
        if let ifNotExists {
            data = try read(from: location, default: Self.nonexistentValue)
            guard data != Self.nonexistentValue else { return ifNotExists }
        } else {
            data = try read(from: location)
        }
        return try decoder.decode(type, data)
    }
}

public struct FileStoreCoder<T: Codable> {
    public var encoder: ObjectEncoder<T>
    public var decoder: ObjectDecoder<T>
    
    public init(encoder: ObjectEncoder<T>, decoder: ObjectDecoder<T>) {
        self.encoder = encoder
        self.decoder = decoder
    }
}

extension FileStoreCoder {
    public static func json(_ formatting: JSONEncoder.OutputFormatting = []) -> Self {
        .init(encoder: .json(formatting), decoder: .json())
    }
    
    public static func plist(_ format: PropertyListSerialization.PropertyListFormat = .xml) -> Self {
        .init(encoder: .plist(format), decoder: .plist())
    }
}
