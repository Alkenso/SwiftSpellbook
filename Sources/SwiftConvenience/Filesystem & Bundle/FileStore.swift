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
    private let read: (URL) throws -> T
    private let write: (T, URL) throws -> Void
    
    public init(read: @escaping (URL) throws -> T, write: @escaping (T, URL) throws -> Void) {
        self.read = read
        self.write = write
    }
    
    public func read(from location: URL) throws -> T { try read(location) }
    public func write(_ value: T, to location: URL) throws { try write(value, location) }
}

extension FileStore where T == Data {
    public static var standard: FileStore {
        FileStore<Data>(
            read: { try Data(contentsOf: $0) },
            write: { try $0.write(to: $1) }
        )
    }
}

extension FileStore {
    public func synchronized(on queue: DispatchQueue) -> Self {
        .init(
            read: { location in try queue.sync { try self.read(from: location) } },
            write: { value, location in try queue.sync(flags: .barrier) { try self.write(value, to: location) } }
        )
    }
}

// MARK: - Exact file

extension FileStore {
    public func exact(_ location: URL) -> Exact {
        .init(store: self, location: location)
    }
    
    public struct Exact {
        let store: FileStore
        public let location: URL
        
        public func read() throws -> T {
            try store.read(location)
        }
        
        public func write(_ value: T) throws {
            try store.write(value, location)
        }
    }
}

// MARK: - Codable

extension FileStore where T == Data {
    public func codable<U: Codable>(_ type: U.Type, using coder: FileStoreCoder<U>) -> FileStore<U> {
        .init(
            read: { try decode(U.self, from: $0, using: coder.decoder) },
            write: { try encode($0, to: $1, using: coder.encoder) }
        )
    }
    
    public func encode<U: Encodable>(_ value: U, to location: URL, using encoder: ObjectEncoder<U>) throws {
        let representation = try encoder.encode(value)
        try write(representation, to: location)
    }
    
    public func decode<U: Decodable>(_ type: U.Type, from location: URL, using decoder: ObjectDecoder<U>) throws -> U {
        let representation = try read(from: location)
        return try decoder.decode(U.self, representation)
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
    public static func json(_ format: JSONEncoder.OutputFormatting = []) -> Self {
        .init(encoder: .json(format), decoder: .json())
    }

    public static func plist(_ format: PropertyListSerialization.PropertyListFormat = .xml) -> Self {
        .init(encoder: .plist(format), decoder: .plist())
    }
}
