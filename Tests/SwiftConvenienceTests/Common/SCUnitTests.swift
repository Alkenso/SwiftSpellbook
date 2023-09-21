import SwiftConvenience
import SwiftConvenienceTestUtils
import XCTest

final class SCUnitTests: XCTestCase {
    func test() {
        XCTAssertEqual(SCUnitInformationStorage.convert(1, to: .kilobyte), 1.0 / 1024)
        XCTAssertEqual(SCUnitInformationStorage.convert(1, .kilobyte), 1.0 * 1024)
        XCTAssertEqual(SCUnitInformationStorage.convert(1, .kilobyte, to: .kilobyte), 1)
        XCTAssertEqual(SCUnitInformationStorage.convert(1, .megabyte, to: .kilobyte), 1024)
        
        XCTAssertEqual(SCUnitTime.convert(1, .minute), 60)
        XCTAssertEqual(SCUnitTime.convert(1, .hour), 60 * 60)
        XCTAssertEqual(SCUnitTime.convert(1, .day), 24 * 60 * 60)
        XCTAssertEqual(SCUnitTime.convert(1, .day, to: .hour), 24)
    }
}
