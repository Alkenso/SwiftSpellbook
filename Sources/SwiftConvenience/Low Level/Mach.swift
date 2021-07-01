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


// MARK: - audit_token_t

public extension audit_token_t {
    /// Returns current task audit token.
    static var current: audit_token_t? {
        withTask(mach_task_self_)
    }
    
    /// Returns task audit token.
    static func withTask(_ task: task_name_t) -> audit_token_t? {
        var token = audit_token_t()
        
        var size = mach_msg_type_number_t(MemoryLayout<audit_token_t>.size / MemoryLayout<natural_t>.size)
        let kernReturn = withUnsafeMutablePointer(to: &token) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 0) {
                task_info(task, task_flavor_t(TASK_AUDIT_TOKEN), $0, &size)
            }
        }
        
        return kernReturn == KERN_SUCCESS ? token : nil
    }
}

extension audit_token_t: Hashable {
    public static func == (lhs: audit_token_t, rhs: audit_token_t) -> Bool {
        withUnsafeBytes(of: lhs) { first -> Bool in
            withUnsafeBytes(of: rhs) { second -> Bool in
                guard first.count == second.count else { return false }
                guard let firstAddr = first.baseAddress, let secondAddr = second.baseAddress else { return false }
                return memcmp(firstAddr, secondAddr, first.count) == 0
            }
        }
    }
    
    public func hash(into hasher: inout Hasher) {
        withUnsafeBytes(of: self) { hasher.combine(bytes: $0) }
    }
}

extension audit_token_t: Codable {
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        self = audit_token_t()
        self.val.0 = try container.decode(UInt32.self)
        self.val.1 = try container.decode(UInt32.self)
        self.val.2 = try container.decode(UInt32.self)
        self.val.3 = try container.decode(UInt32.self)
        self.val.4 = try container.decode(UInt32.self)
        self.val.5 = try container.decode(UInt32.self)
        self.val.6 = try container.decode(UInt32.self)
        self.val.7 = try container.decode(UInt32.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        try container.encode(val.0)
        try container.encode(val.1)
        try container.encode(val.2)
        try container.encode(val.3)
        try container.encode(val.4)
        try container.encode(val.5)
        try container.encode(val.6)
        try container.encode(val.7)
    }
}
