@testable import SpellbookFoundation

import XCTest

class UnsafeTests: XCTestCase {
    func test_bzero() {
        let zeroedPtr = UnsafeMutableRawPointer.allocate(byteCount: 4, alignment: 1)
        defer { zeroedPtr.deallocate() }
        bzero(zeroedPtr, 4)
        
        let mutablePtr = UnsafeMutablePointer<UInt32>.allocate(capacity: 1)
        defer { mutablePtr.deallocate() }
        mutablePtr.pointee = 0xFF_FF_FF_FF
        mutablePtr.bzero()
        XCTAssertEqual(memcmp(mutablePtr, zeroedPtr, 4), 0)
        
        let mutableRawPtr = UnsafeMutableRawPointer.allocate(byteCount: 4, alignment: 1)
        defer { mutableRawPtr.deallocate() }
        mutableRawPtr.bindMemory(to: UInt32.self, capacity: 1).pointee = 0xFF_FF_FF_FF
        mutableRawPtr.bzero(MemoryLayout<UInt32>.size)
        XCTAssertEqual(memcmp(mutableRawPtr, zeroedPtr, 4), 0)
        
        let mutableBufferPtr = UnsafeMutableBufferPointer<UInt32>.allocate(capacity: 1)
        defer { mutableBufferPtr.deallocate() }
        mutableBufferPtr[0] = 0xFF_FF_FF_FF
        mutableBufferPtr.bzero()
        XCTAssertEqual(memcmp(mutableBufferPtr.baseAddress, zeroedPtr, 4), 0)
        
        let mutableRawBufferPtr = UnsafeMutableRawBufferPointer.allocate(byteCount: 4, alignment: 1)
        defer { mutableRawBufferPtr.deallocate() }
        mutableRawBufferPtr[0] = 0xFF
        mutableRawBufferPtr[1] = 0xFF
        mutableRawBufferPtr[2] = 0xFF
        mutableRawBufferPtr[3] = 0xFF
        mutableRawBufferPtr.bzero()
        XCTAssertEqual(memcmp(mutableRawBufferPtr.baseAddress, zeroedPtr, 4), 0)
        
        let autoreleasingMutableBackingPtr = UnsafeMutablePointer<UInt32>.allocate(capacity: 1)
        defer { autoreleasingMutableBackingPtr.deallocate() }
        let autoreleasingMutablePtr = AutoreleasingUnsafeMutablePointer<UInt32>(autoreleasingMutableBackingPtr)
        autoreleasingMutablePtr.pointee = 0xFF_FF_FF_FF
        autoreleasingMutablePtr.bzero()
        XCTAssertEqual(memcmp(autoreleasingMutablePtr, zeroedPtr, 4), 0)
    }
}
