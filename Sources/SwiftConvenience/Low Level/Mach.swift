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
    static func current() throws -> audit_token_t {
        try withTask(mach_task_self_)
    }
    
    /// Returns task audit token.
    static func withTask(_ task: task_name_t) throws -> audit_token_t {
        var token = audit_token_t()
        
        var size = mach_msg_type_number_t(MemoryLayout<audit_token_t>.size / MemoryLayout<natural_t>.size)
        let kernReturn = withUnsafeMutablePointer(to: &token) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 0) {
                task_info(task, task_flavor_t(TASK_AUDIT_TOKEN), $0, &size)
            }
        }
        
        if kernReturn == KERN_SUCCESS {
            return token
        } else {
            throw NSError(
                domain: NSMachErrorDomain,
                code: Int(kernReturn),
                userInfo: [
                    NSDebugDescriptionErrorKey: "Failed to get audit_token for task = \(task). task_info failed with error = \(kernReturn)"
                ]
            )
        }
    }
}

#if os(macOS)

public extension audit_token_t {
    var auid: uid_t { audit_token_to_auid(self) }
    var euid: uid_t { audit_token_to_euid(self) }
    var egid: gid_t { audit_token_to_egid(self) }
    var ruid: uid_t { audit_token_to_ruid(self) }
    var rgid: gid_t { audit_token_to_rgid(self) }
    var pid: pid_t { audit_token_to_pid(self) }
    var asid: au_asid_t { audit_token_to_asid(self) }
    var pidversion: Int32 { audit_token_to_pidversion(self) }
}

#endif


// MARK: - Mach Time

public extension TimeInterval {
    /// Converts mach_time into TimeInterval using mach_timebase_info.
    /// Returns nil if mach_timebase_info fails.
    init?(machTime: UInt64) {
        guard let timeInfo = mach_timebase_info.system.value else { return nil }
        
        let nanos = TimeInterval(machTime * UInt64(timeInfo.numer)) / TimeInterval(timeInfo.denom)
        self = nanos / TimeInterval(NSEC_PER_SEC)
    }
}

public extension mach_timebase_info {
    static let system: Result<mach_timebase_info, Error> = {
        var info = mach_timebase_info()
        let kernReturn = mach_timebase_info(&info)
        if kernReturn == KERN_SUCCESS {
            return .success(info)
        } else {
            return .failure(
                NSError(
                    domain: NSMachErrorDomain,
                    code: Int(kernReturn),
                    userInfo: [
                        NSDebugDescriptionErrorKey: "mach_timebase_info fails with result \(kernReturn)"
                    ]
                )
            )
        }
    }()
}
