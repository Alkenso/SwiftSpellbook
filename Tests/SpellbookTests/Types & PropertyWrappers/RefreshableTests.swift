import SpellbookFoundation
import XCTest

class RefreshableTests: XCTestCase {
    func test_basic() {
        var expired = false
        var newValue = 1
        var value = Refreshable(
            wrappedValue: 10,
            expire: .init(checkExpired: { _ in expired }, onUpdate: { _ in expired = false }),
            source: .init(newValue: { _ in newValue })
        )
        
        //  Refreshable holds value it initialized with
        XCTAssertEqual(value.wrappedValue, 10)
        
        //  Mark Refreshable as expired. Value should be updated, expired state reset
        expired = true
        XCTAssertEqual(value.wrappedValue, 1)
        XCTAssertEqual(expired, false)
        
        //  New value will be picked up only when previous is expired
        newValue = 20
        XCTAssertEqual(value.wrappedValue, 1)
        expired = true
        XCTAssertEqual(value.wrappedValue, 20)
    }
    
    func test_ttl() {
        var value = Refreshable(
            wrappedValue: 10,
            expire: .ttl(0.05),
            source: .defaultValue(1)
        )
        
        XCTAssertEqual(value.wrappedValue, 10)
        
        //  Value is expired after 0.1 and reset to default
        Thread.sleep(forTimeInterval: 0.1)
        XCTAssertEqual(value.wrappedValue, 1)
    }
}
