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

public struct UnixUser: Equatable, Codable {
    /// User's login name.
    public var name: String
    /// Numerical user ID.
    public var uid: uid_t
    /// Numerical group ID.
    public var gid: gid_t
    /// Initial working directory.
    public var dir: String
    /// Program to use as shell.
    public var shell: String
    
    public init(name: String, uid: uid_t, gid: gid_t, dir: String, shell: String) {
        self.name = name
        self.uid = uid
        self.gid = gid
        self.dir = dir
        self.shell = shell
    }
}

extension UnixUser {
    public init?(name: String) {
        guard let native = getpwnam(name) else { return nil }
        self.init(native: native.pointee)
    }
    
    public init?(uid: uid_t) {
        guard let native = getpwuid(uid) else { return nil }
        self.init(native: native.pointee)
    }
    
    public init(native: passwd) {
        self.init(
            name: String(cString: native.pw_name), uid: native.pw_uid, gid: native.pw_gid,
            dir:  String(cString: native.pw_dir), shell:  String(cString: native.pw_shell)
        )
    }
    
    public static var loginUsers: [UnixUser] {
        let usersDir = FileManager.default.urls(for: .userDirectory, in: .localDomainMask)[0].path
        let users = passwdUsers.filter { $0.dir.starts(with: usersDir) }
        return users
    }
    
    public static var passwdUsers: [UnixUser] {
        setpwent()
        let users = AnySequence { AnyIterator(getpwent) }
            .compactMap { UnixUser(native: $0.pointee) }
        endpwent()
        
        return users
    }
}

extension UnixUser {
    public var allGroups: [UnixGroup] {
        let maxAttempts: Int32 = 100
        for i in 1...maxAttempts {
            var count = i * 100
            var groups = [Int32](repeating: 0, count: Int(count))
            let status = groups.withUnsafeMutableBufferPointer {
                getgrouplist(name, Int32(gid), $0.baseAddress, &count)
            }
            if status != -1 {
                return groups[0..<Int(count)].map { gid_t($0) }.map {
                    UnixGroup(gid: $0) ?? UnixGroup(name: "<unknown>", gid: $0)
                }
            }
        }
        return []
    }
}

extension UnixUser: CustomStringConvertible {
    public var description: String {
        "\(name)|\(uid)/\(gid)"
    }
}

#if os(macOS)
import SystemConfiguration

extension UnixUser {
    public var currentlyLoggedIn: UnixUser? {
        var uid: uid_t = 0
        guard SCDynamicStoreCopyConsoleUser(nil, &uid, nil) != nil else { return nil }
        guard let user = UnixUser(uid: uid) else { return nil }
        return user
    }
}
#endif
