import SpellbookFoundation
import SpellbookTestUtils
import XCTest

final class SBUnitTests: XCTestCase {
    func test() {
        XCTAssertEqual(SBUnitInformationStorage.convert(1, to: .kilobyte), 1.0 / 1024)
        XCTAssertEqual(SBUnitInformationStorage.convert(1, .kilobyte), 1.0 * 1024)
        XCTAssertEqual(SBUnitInformationStorage.convert(1, .kilobyte, to: .kilobyte), 1)
        XCTAssertEqual(SBUnitInformationStorage.convert(1, .megabyte, to: .kilobyte), 1024)
        
        XCTAssertEqual(SBUnitTime.convert(1, .minute), 60)
        XCTAssertEqual(SBUnitTime.convert(1, .hour), 60 * 60)
        XCTAssertEqual(SBUnitTime.convert(1, .day), 24 * 60 * 60)
        XCTAssertEqual(SBUnitTime.convert(1, .day, to: .hour), 24)
    }
}
