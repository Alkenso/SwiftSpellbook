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

#if os(macOS)

import Foundation

public struct UnixGroup: Codable {
    public var name: String
    public var gid: gid_t
    
    public init(name: String, gid: gid_t) {
        self.name = name
        self.gid = gid
    }
}

extension UnixGroup {
    public init?(name: String) {
        guard let native = getgrnam(name) else { return nil }
        self.init(native: native.pointee)
    }
    
    public init?(gid: gid_t) {
        setgrent()
        guard let native = getgrgid(gid) else { return nil }
        self.init(native: native.pointee)
    }
    
    public init(native: group) {
        self.init(name: String(cString: native.gr_name), gid: native.gr_gid)
    }
}

extension UnixGroup {
    public static var allGroups: [UnixGroup] {
        setgrent()
        let groups = AnySequence { AnyIterator(getgrent) }
            .compactMap { UnixGroup(native: $0.pointee) }
        endgrent()
        
        return groups
    }
}

extension UnixGroup: CustomStringConvertible {
    public var description: String {
        "\(name)|\(gid)"
    }
}

#if canImport(Darwin) // Apple world only.
extension UnixGroup {
    public static let wheel = UnixGroup(name: "wheel", gid: 0)
    public static let staff = UnixGroup(name: "staff", gid: 20)
    public static let admin = UnixGroup(name: "admin", gid: 80)
}
#endif

#endif
