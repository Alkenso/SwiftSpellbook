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

extension audit_token_t {
    /// Returns current task audit token.
    public static func current() throws -> audit_token_t {
        try audit_token_t(task: mach_task_self_)
    }
    
    /// Returns task for pid.
    public init(pid: pid_t) throws {
        let taskName = try NSError.mach.try { task_name_for_pid(mach_task_self_, pid, $0) }
        try self.init(task: taskName)
    }
    
    /// Returns task audit token.
    public init(task: task_name_t) throws {
        var size = mach_msg_type_number_t(MemoryLayout<audit_token_t>.size / MemoryLayout<natural_t>.size)
        self = try NSError.mach
            .debugDescription("Failed to get audit_token for task = \(task) using task_info()")
            .try { (ptr: UnsafeMutablePointer<audit_token_t>) in
                ptr.withMemoryRebound(to: integer_t.self, capacity: 0) {
                    task_info(task, task_flavor_t(TASK_AUDIT_TOKEN), $0, &size)
                }
            }
    }
}

#if os(macOS)

extension audit_token_t {
    public var auid: uid_t { audit_token_to_auid(self) }
    public var euid: uid_t { audit_token_to_euid(self) }
    public var egid: gid_t { audit_token_to_egid(self) }
    public var ruid: uid_t { audit_token_to_ruid(self) }
    public var rgid: gid_t { audit_token_to_rgid(self) }
    public var pid: pid_t { audit_token_to_pid(self) }
    public var asid: au_asid_t { audit_token_to_asid(self) }
    public var pidversion: Int32 { audit_token_to_pidversion(self) }
}

#endif


// MARK: - Mach Time

extension TimeInterval {
    /// Converts mach_time into TimeInterval using mach_timebase_info.
    /// Returns nil if mach_timebase_info fails.
    public init?(machTime: UInt64) {
        guard let timebase = try? mach_timebase_info.system() else { return nil }
        self.init(machTime: machTime, timebase: timebase)
    }
    
    public init(machTime: UInt64, timebase: mach_timebase_info) {
        let nanos = TimeInterval(machTime * UInt64(timebase.numer)) / TimeInterval(timebase.denom)
        self = nanos / TimeInterval(NSEC_PER_SEC)
    }
}

extension mach_timebase_info {
    public static func system() throws -> mach_timebase_info {
        var info = mach_timebase_info()
        let kernReturn = mach_timebase_info(&info)
        if kernReturn == KERN_SUCCESS {
            return info
        } else {
            throw NSError(
                domain: NSMachErrorDomain,
                code: Int(kernReturn),
                userInfo: [
                    NSDebugDescriptionErrorKey: "mach_timebase_info fails with result \(kernReturn)"
                ]
            )
        }
    }
}
