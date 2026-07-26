//  MIT License
//
//  Copyright (c) 2026 Alkenso (Vladimir Vashurkin)
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

import SpellbookCrash
import SpellbookFoundation

import Testing

@Suite(.serialized)
struct CrashTests {
    init() {
        CrashReportAugmentation.removeAll(.signature)
        CrashReportAugmentation.removeAll(.backtrace)
    }
    
    @Test
    func addRemove() async throws {
        #expect(CrashInfo.string(\.signature) == nil)
        #expect(CrashInfo.string(\.backtrace) == nil)
        
        let sigMsg = CrashReportAugmentation.addMessage("sig-msg-1")
        let btMsg = CrashReportAugmentation.addMessage(target: .backtrace, "bt-msg-1")
        
        #expect(CrashInfo.string(\.signature)?.contains("sig-msg-1") == true)
        #expect(CrashInfo.string(\.signature)?.contains("bt-msg-1") == false)
        
        #expect(CrashInfo.string(\.backtrace)?.contains("sig-msg-1") == false)
        #expect(CrashInfo.string(\.backtrace)?.contains("bt-msg-1") == true)
        
        CrashReportAugmentation.removeMessage(btMsg)
        #expect(CrashInfo.string(\.signature) != nil)
        #expect(CrashInfo.string(\.backtrace) == nil)
        
        CrashReportAugmentation.removeMessage(sigMsg)
        #expect(CrashInfo.string(\.signature) == nil)
        #expect(CrashInfo.string(\.backtrace) == nil)
    }
    
    @Test
    func withMessage() async throws {
        #expect(CrashInfo.string(\.signature) == nil)
        
        CrashReportAugmentation.withMessage("sig-msg-1") {
            #expect(CrashInfo.string(\.signature)?.contains("sig-msg-1") == true)
        }
        #expect(CrashInfo.string(\.signature) == nil)
        
        _ = CrashReportAugmentation.addMessage("sig-msg-manual")
        try await CrashReportAugmentation.withMessage("sig-msg-2") {
            try await Task.sleep(forTimeInterval: 0.001)
            #expect(CrashInfo.string(\.signature)?.contains("sig-msg-2") == true)
        }
        #expect(CrashInfo.string(\.signature)?.contains("sig-msg-2") == false)
        #expect(CrashInfo.string(\.signature)?.contains("sig-msg-manual") == true)
    }
}

private extension CrashInfo {
    static func string(_ keyPath: KeyPath<CrashInfo, UnsafeMutablePointer<CChar>?>) -> String? {
        guard let pointer = shared.pointee[keyPath: keyPath] else { return nil }
        return String(cString: pointer)
    }
}
