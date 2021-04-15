import SwiftConvenience
import SwiftConvenienceTestUtils

import XCTest


class StandardTypesExtensionsTests: XCTestCase {
    func test_Error_unwrapSafely() {
        let error: Error? = TestError()
        let unwrapped = error.unwrapSafely()
        XCTAssertNotNil(unwrapped as? TestError)
        
        let nilError: Error? = nil
        let unwrappedNil = nilError.unwrapSafely()
        XCTAssertNotNil(unwrappedNil as? CommonError)
    }
    
    func test_Result_value_error() {
        let resultWithValue: Result<Bool, Error> = .success(true)
        
        XCTAssertTrue((resultWithValue.value != nil))
        XCTAssertNil(resultWithValue.error)
        
        
        let resultWithError: Result<Bool, Error> = .failure(TestError())
        
        XCTAssertNil(resultWithError.value)
        XCTAssertNotNil(resultWithError.error)
    }
    
    func test_Data_PODTypes() {
        XCTAssertEqual(Data(pod: 0x10FF20), Data([0x20, 0xFF, 0x10, 0x00, 0x00, 0x00, 0x00, 0x00]))
        XCTAssertEqual(Data(pod: 0), Data([0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]))
        
        XCTAssertEqual(Data([0x20, 0xFF, 0x10, 0x00, 0x00, 0x00, 0x00, 0x00]).pod(of: Int.self), 0x10FF20)
        XCTAssertEqual(Data([0x20, 0xFF, 0x10, 0x00]).pod(of: Int32.self), 0x10FF20)
        XCTAssertEqual(Data([0x20, 0xFF, 0x10, 0x00]).pod(of: Int.self), nil)
    }
    
    func test_Data_fromHexString() {
        XCTAssertEqual(
            Data(hexString: "0001100AA0FF00"),
            Data([0x00, 0x01, 0x10, 0x0A, 0xA0, 0xFF, 0x00])
        )
        XCTAssertEqual(
            Data(hexString: "0x0001100AA0FF00"),
            Data([0x00, 0x01, 0x10, 0x0A, 0xA0, 0xFF, 0x00])
        )
        XCTAssertEqual(
            Data(hexString: ""),
            Data()
        )
        XCTAssertEqual(
            Data(hexString: "0a10c"),
            nil
        )
        XCTAssertEqual(
            Data(hexString: "a"),
            nil
        )
        XCTAssertEqual(
            Data(hexString: "qq"),
            nil
        )
    }
    
    func test_Data_toHexString() {
        XCTAssertEqual(
            Data([0x00, 0x01, 0x10, 0x0A, 0xA0, 0xFF, 0x00]).hexString.uppercased(),
            "0001100AA0FF00"
        )
        XCTAssertEqual(
            Data().hexString,
            ""
        )
    }
}
