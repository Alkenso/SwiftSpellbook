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

extension Date {
    public init?(machTime: UInt64) {
        guard let machSeconds = TimeInterval(machTime: machTime) else { return nil }
        self = ProcessInfo.processInfo.systemBootDate.addingTimeInterval(machSeconds)
    }
    
    public var machTime: UInt64? {
        guard let timebase = try? mach_timebase_info.system() else { return nil }
        
        let seconds = timeIntervalSince(ProcessInfo.processInfo.systemBootDate)
        let nanos = seconds * TimeInterval(NSEC_PER_SEC)
        let machTime = nanos * TimeInterval(timebase.denom) / TimeInterval(timebase.numer)
        return UInt64(machTime)
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
                    NSDebugDescriptionErrorKey: "mach_timebase_info fails with result \(kernReturn)",
                ]
            )
        }
    }
}
