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
    
    public func read(from location: URL) throws -> T { try read(location) }
    public func write(_ value: T, to location: URL) throws { try write(value, location) }
}

extension FileStore {
    public static var standard: FileStore<Data> {
        FileStore<Data>(
            read: { try Data(contentsOf: $0) },
            write: { try $0.write(to: $1) }
        )
    }
}

// MARK: - Exact file

extension FileStore {
    public func exact(_ location: URL, queue: DispatchQueue? = nil) -> Exact {
        .init(store: self, location: location, queue: queue)
    }
    
    public struct Exact {
        let store: FileStore
        let location: URL
        let queue: DispatchQueue?
        
        public func read() throws -> T {
            guard let queue = queue else { return try store.read(location) }
            return try queue.sync { try store.read(location) }
        }
        
        public func write(_ value: T) throws {
            guard let queue = queue else { return try store.write(value, location) }
            try queue.sync { try store.write(value, location) }
        }
    }
}

// MARK: - Codable

extension FileStore {
    public func codable<U: Codable>(using coder: FileStoreCoder<U, T>) -> FileStore<U> {
        .init(
            read: { try decode(U.self, from: $0, using: coder.decoder) },
            write: { try encode($0, to: $1, using: coder.encoder) }
        )
    }
    
    public func encode<U: Encodable>(_ value: U, to location: URL, using encoder: FileStoreEncoder<U, T>) throws {
        let representation = try encoder(value)
        try write(representation, to: location)
    }
    
    public func decode<U: Decodable>(_ type: U.Type, from location: URL, using decoder: FileStoreDecoder<T, U>) throws -> U {
        let representation = try read(from: location)
        return try decoder(representation)
    }
}

public typealias FileStoreEncoder<Input: Encodable, Output> = ClosureT<Input, Output>
public typealias FileStoreDecoder<Input, Output: Decodable> = ClosureT<Input, Output>
public struct FileStoreCoder<T: Codable, Representation> {
    public var encoder: FileStoreEncoder<T, Representation>
    public var decoder: FileStoreDecoder<Representation, T>
}

extension FileStoreEncoder where T: Encodable, R == Data {
    public static func json(encoder: JSONEncoder = JSONEncoder()) -> Self {
        .init(encoder.encode)
    }
    
    public static func plist(encoder: PropertyListEncoder = PropertyListEncoder(), format: PropertyListSerialization.PropertyListFormat? = nil) -> Self {
        format.flatMap { encoder.outputFormat = $0 }
        return .init(encoder.encode)
    }
}

extension FileStoreDecoder where T == Data, R: Decodable {
    public static func json(decoder: JSONDecoder = JSONDecoder()) -> Self {
        .init { try decoder.decode(R.self, from: $0) }
    }
    
    public static func plist(decoder: PropertyListDecoder = PropertyListDecoder()) -> Self {
        return .init { try decoder.decode(R.self, from: $0) }
    }
}

extension FileStoreCoder where Representation == Data {
    public static var json: Self {
        .init(encoder: .json(), decoder: .json())
    }
    
    public static func plist(_ format: PropertyListSerialization.PropertyListFormat) -> Self {
        .init(encoder: .plist(format: format), decoder: .plist())
    }
}
