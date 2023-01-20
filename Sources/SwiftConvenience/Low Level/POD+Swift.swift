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

/// PODCodable performs coding of POD value as single Data object.
public protocol PODCodable: Codable {}

extension PODCodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let data = try container.decode(Data.self)
        
        if let value = data.pod(exactly: Self.self) {
            self = value
        } else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Unable to decode \(Self.self) from data of size = \(data.count)"
                )
            )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        let data = Data(pod: self)
        try container.encode(data)
    }
}

/// PODUnsafeHashable uses raw memory comparison to check
/// whether values are equal or hash them.
/// You MUST be very careful and apply it only to types with no padding between fields.
///
/// Here is example of struct with padding between fields. Applying raw memory computations
/// to it leads to invalid results in runtime that are confusing and hard-to-find:
/// ```
/// struct StruWithPadding {
///     var a: UInt64
///     var b: UInt32
///     // 4-byte padding. It may be filled with random bytes in runtime.
///     var a: UInt64
/// }
public protocol PODUnsafeHashable: Hashable {}

extension PODUnsafeHashable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        unsafeMemoryEquals(lhs, rhs)
    }
    
    public func hash(into hasher: inout Hasher) {
        withUnsafeBytes(of: self) { hasher.combine(bytes: $0) }
    }
}

public protocol SafePOD: PODCodable {}
public protocol UnsafePOD: PODUnsafeHashable {}

// MARK: - Oftenly used POD types

extension timespec: SafePOD, UnsafePOD {}
extension fsid_t: SafePOD, UnsafePOD {}
extension attrlist: SafePOD, UnsafePOD {}
extension attribute_set: SafePOD, UnsafePOD {}
extension attrreference: SafePOD, UnsafePOD {}
extension diskextent: SafePOD, UnsafePOD {}

extension stat: SafePOD {}
extension statfs: SafePOD {}

extension timeval: SafePOD {}

extension stat: Hashable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.st_dev == rhs.st_dev &&
            lhs.st_mode == rhs.st_mode &&
            lhs.st_nlink == rhs.st_nlink &&
            lhs.st_ino == rhs.st_ino &&
            lhs.st_uid == rhs.st_uid &&
            lhs.st_gid == rhs.st_gid &&
            lhs.st_rdev == rhs.st_rdev &&
            lhs.st_atimespec == rhs.st_atimespec &&
            lhs.st_mtimespec == rhs.st_mtimespec &&
            lhs.st_ctimespec == rhs.st_ctimespec &&
            lhs.st_birthtimespec == rhs.st_birthtimespec &&
            lhs.st_size == rhs.st_size &&
            lhs.st_blocks == rhs.st_blocks &&
            lhs.st_blksize == rhs.st_blksize &&
            lhs.st_flags == rhs.st_flags &&
            lhs.st_gen == rhs.st_gen &&
            lhs.st_lspare == rhs.st_lspare &&
            lhs.st_qspare == rhs.st_qspare
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(st_dev)
        hasher.combine(st_mode)
        hasher.combine(st_nlink)
        hasher.combine(st_ino)
        hasher.combine(st_uid)
        hasher.combine(st_gid)
        hasher.combine(st_rdev)
        hasher.combine(st_atimespec)
        hasher.combine(st_mtimespec)
        hasher.combine(st_ctimespec)
        hasher.combine(st_birthtimespec)
        hasher.combine(st_size)
        hasher.combine(st_blocks)
        hasher.combine(st_blksize)
        hasher.combine(st_flags)
        hasher.combine(st_gen)
        hasher.combine(st_lspare)
        withUnsafeBytes(of: st_qspare) { hasher.combine(bytes: $0) }
    }
}

extension statfs: Hashable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.f_bsize == rhs.f_bsize &&
            lhs.f_iosize == rhs.f_iosize &&
            lhs.f_blocks == rhs.f_blocks &&
            lhs.f_bfree == rhs.f_bfree &&
            lhs.f_bavail == rhs.f_bavail &&
            lhs.f_files == rhs.f_files &&
            lhs.f_ffree == rhs.f_ffree &&
            unsafeMemoryEquals(lhs.f_fsid, rhs.f_fsid) &&
            lhs.f_owner == rhs.f_owner &&
            lhs.f_type == rhs.f_type &&
            lhs.f_flags == rhs.f_flags &&
            lhs.f_fssubtype == rhs.f_fssubtype &&
            unsafeMemoryEquals(lhs.f_fstypename, rhs.f_fstypename) &&
            unsafeMemoryEquals(lhs.f_mntonname, rhs.f_mntonname) &&
            unsafeMemoryEquals(lhs.f_mntfromname, rhs.f_mntfromname) &&
            lhs.f_flags_ext == rhs.f_flags_ext
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(f_bsize)
        hasher.combine(f_iosize)
        hasher.combine(f_blocks)
        hasher.combine(f_bfree)
        hasher.combine(f_bavail)
        hasher.combine(f_files)
        hasher.combine(f_ffree)
        hasher.combine(f_fsid)
        hasher.combine(f_owner)
        hasher.combine(f_type)
        hasher.combine(f_flags)
        hasher.combine(f_fssubtype)
        withUnsafeBytes(of: f_fstypename) { hasher.combine(bytes: $0) }
        withUnsafeBytes(of: f_mntonname) { hasher.combine(bytes: $0) }
        withUnsafeBytes(of: f_mntfromname) { hasher.combine(bytes: $0) }
        hasher.combine(f_flags_ext)
    }
}

extension timeval: Hashable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.tv_sec == rhs.tv_sec &&
            lhs.tv_usec == rhs.tv_usec
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(tv_sec)
        hasher.combine(tv_usec)
    }
}
