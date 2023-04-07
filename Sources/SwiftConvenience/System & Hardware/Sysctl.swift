//  MIT License
//
//  Copyright (c) 2023 Alkenso (Vladimir Vashurkin)
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

public enum Sysctl {}

extension Sysctl {
    public static func procArgs(for pid: pid_t) throws -> (executable: String, args: [String]) {
        let data = try argumentData(for: pid)
        let (executable, args) = try argumentsFromArgumentData(data, pid: pid)
        return (executable, Array(args.dropFirst()))
    }
    
    private static func argumentData(for pid: pid_t) throws -> Data {
        var mibArgmax = [CTL_KERN, KERN_ARGMAX]
        var argMax: CInt = 0
        var argMaxSize = MemoryLayout.size(ofValue: argMax)
        try NSError.mach
            .debugDescription("sysctl (KERN_ARGMAX) for pid \(pid)")
            .try { sysctl(&mibArgmax, u_int(mibArgmax.count), &argMax, &argMaxSize, nil, 0) }
        
        guard argMaxSize > 0 else {
            throw CommonError.unexpected("sysctl (KERN_ARGMAX) for pid \(pid) failed: argMaxSize == 0")
        }
        
        var argsData = Data(count: Int(argMax))
        var mibProcArgs = [CTL_KERN, KERN_PROCARGS2, pid]
        var argsDataSize = Int(argMax)
        try argsData.withUnsafeMutableBytes { buffer in
            try NSError.mach
                .debugDescription("sysctl (KERN_PROCARGS2) for pid \(pid)")
                .try { sysctl(&mibProcArgs, u_int(mibProcArgs.count), buffer.baseAddress, &argsDataSize, nil, 0) }
        }
        argsData = argsData.prefix(argsDataSize)
        
        return argsData
    }
    
    private static func argumentsFromArgumentData(_ data: Data, pid: pid_t) throws -> (String, [String]) {
        // The algorithm here was picked from the Darwin source for `ps`.
        // <https://opensource.apple.com/source/adv_cmds/adv_cmds-176/ps/print.c.auto.html>
        
        var remaining = data[...]
        guard remaining.count >= 6 else {
            throw CommonError.unexpected("sysctl (KERN_PROCARGS2) for pid \(pid) failed: empty executable and args")
        }
        
        let count32 = remaining.prefix(4).reversed().reduce(0, { $0 << 8 | UInt32($1) })
        remaining = remaining.dropFirst(4)

        // Parse the executable path.
        guard let executablePath = remaining.popString(while: { $0 != 0 }) else {
            throw CommonError.unexpected("sysctl (KERN_PROCARGS2) for pid \(pid) failed: empty executable")
        }
        remaining = remaining.drop(while: { $0 == 0 })

        // Now parse `argv[0]` through `argv[argc - 1]`.

        var args: [String] = []
        for i in 0..<count32 {
            guard let arg = remaining.popString(while: { $0 != 0 }) else {
                throw CommonError.unexpected("sysctl (KERN_PROCARGS2) for pid \(pid) failed: args is not UTF8 string")
            }
            args.append(arg)
            guard remaining.count != 0 else {
                throw CommonError.unexpected("sysctl (KERN_PROCARGS2) for pid \(pid) failed: unexpected end of args at \(i)/\(count32)")
            }
            remaining = remaining.dropFirst()
        }
        
        return (executablePath, args)
    }
}

extension Data {
    fileprivate mutating func popString(`while`: (Element) -> Bool) -> String? {
        let bytes = prefix(while: `while`)
        self = dropFirst(bytes.count)
        guard let string = String(data: bytes, encoding: .utf8) else { return nil }
        return !string.isEmpty ? string : nil
    }
}

#endif
