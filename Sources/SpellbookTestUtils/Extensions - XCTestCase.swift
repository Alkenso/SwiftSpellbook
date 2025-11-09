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

import SpellbookFoundation
import XCTest

extension XCTestCase {
#if SPELLBOOK_SLOW_CI_x10
    public nonisolated(unsafe) static var waitRate = 10.0
#elseif SPELLBOOK_SLOW_CI_x20
    public nonisolated(unsafe) static var waitRate = 20.0
#elseif SPELLBOOK_SLOW_CI_x30
    public nonisolated(unsafe) static var waitRate = 30.0
#elseif SPELLBOOK_SLOW_CI_x50
    public nonisolated(unsafe) static var waitRate = 50.0
#elseif SPELLBOOK_SLOW_CI_x100
    public nonisolated(unsafe) static var waitRate = 100.0
#else
    public nonisolated(unsafe) static var waitRate = 1.0
#endif
    
    public nonisolated(unsafe) static var waitTimeout: TimeInterval = 0.5
    
    public static var testBundle: Bundle {
        return Bundle(for: Self.self)
    }
    
    public var testBundle: Bundle {
        Self.testBundle
    }
    
    public static var testTemporaryDirectory: TemporaryDirectory {
        .init(name: testBundle.bundleIdentifier ?? testBundle.bundlePath.lastPathComponent)
    }
    
    public var testTemporaryDirectory: TemporaryDirectory {
        Self.testTemporaryDirectory
    }
    
    @discardableResult
    public func waitForExpectations(timeout: TimeInterval = XCTestCase.waitTimeout) -> Error? {
        waitForExpectations(timeout: timeout, ignoreWaitRate: false)
    }
    
    @discardableResult
    public func waitForExpectations(timeout: TimeInterval = XCTestCase.waitTimeout, ignoreWaitRate: Bool) -> Error? {
        nonisolated(unsafe) let test = self
        return DispatchQueue.syncOnMain {
            nonisolated(unsafe) var error: Error?
            test.waitForExpectations(timeout: timeout * Self.waitRate) {
                error = $0
            }
            return error
        }
    }
    
    public static func sleep(interval: TimeInterval) {
        Thread.sleep(forTimeInterval: interval * Self.waitRate)
    }
    
    public func sleep(interval: TimeInterval) {
        Self.sleep(interval: interval)
    }
    
    public func withScope<R>(body: () throws -> R) rethrows -> R {
        try body()
    }
}
