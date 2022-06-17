import SwiftConvenience
import SwiftConvenienceTestUtils

import XCTest

class StandardTypesExtensionsTests: XCTestCase {
    func test_Error_unwrapSafely() {
        let error: Error? = TestError()
        let unwrapped = error.safelyUnwrapped
        XCTAssertNotNil(unwrapped as? TestError)
        
        let nilError: Error? = nil
        let unwrappedNil = nilError.safelyUnwrapped
        XCTAssertNotNil(unwrappedNil as? CommonError)
    }
    
    func test_Result_success_failure() {
        let resultWithValue: Result<Bool, Error> = .success(true)
        XCTAssertEqual(resultWithValue.success, true)
        XCTAssertNil(resultWithValue.failure)
        
        let resultWithError: Result<Bool, Error> = .failure(TestError())
        XCTAssertNil(resultWithError.success)
        XCTAssertNotNil(resultWithError.failure)
    }
    
    func test_Data_PODTypes_toData() {
        XCTAssertEqual(Data(pod: 0x10ff20), Data([0x20, 0xff, 0x10, 0x00, 0x00, 0x00, 0x00, 0x00]))
        XCTAssertEqual(Data(pod: 0), Data([0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]))
    }
    
    func test_Data_PODTypes_exactly() {
        XCTAssertEqual(Data(pod: 0x10ff20), Data([0x20, 0xff, 0x10, 0x00, 0x00, 0x00, 0x00, 0x00]))
        XCTAssertEqual(Data(pod: 0), Data([0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]))
        
        XCTAssertEqual(Data([0x20, 0xff, 0x10, 0x00, 0x00, 0x00, 0x00, 0x00]).pod(exactly: Int.self), 0x10ff20)
        XCTAssertEqual(Data([0x20, 0xff, 0x10, 0x00]).pod(exactly: Int32.self), 0x10ff20)
        XCTAssertEqual(Data([0x20, 0xff, 0x10, 0x00]).pod(exactly: Int64.self), nil)
    }
    
    func test_Data_PODTypes_adopting() {
        XCTAssertEqual(Data([0x20, 0xff, 0x10, 0x00, 0x00, 0x00, 0x00, 0x00]).pod(adopting: Int.self), 0x10ff20)
        XCTAssertEqual(Data([0x20, 0xff, 0x10]).pod(adopting: Int32.self), 0x10ff20)
        XCTAssertEqual(Data([0x20, 0xff, 0x10]).pod(adopting: Int64.self), 0x10ff20)
    }
    
    func test_Data_fromHexString() {
        XCTAssertEqual(
            Data(hexString: "0001100AA0FF00"),
            Data([0x00, 0x01, 0x10, 0x0a, 0xa0, 0xff, 0x00])
        )
        XCTAssertEqual(
            Data(hexString: "0x0001100AA0FF00"),
            Data([0x00, 0x01, 0x10, 0x0a, 0xa0, 0xff, 0x00])
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
            Data([0x00, 0x01, 0x10, 0x0a, 0xa0, 0xff, 0x00]).hexString.uppercased(),
            "0001100AA0FF00"
        )
        XCTAssertEqual(
            Data().hexString,
            ""
        )
    }
    
    func test_Result_initSuccessFailure() {
        XCTAssertEqual(Result<Int, Error>(success: 10, failure: nil).success, 10)
        XCTAssertNotNil(Result<Int, Error>(success: nil, failure: TestError()).failure)
        XCTAssertNotNil(Result<Int, Error>(success: nil, failure: nil).failure)
        
        XCTAssertEqual(Result<Int, Error>(success: 10, failure: TestError()).success, 10)
        
        //  Special case when Success == Optional
        XCTAssertEqual(Result<Int?, Error>(success: nil, failure: nil).success, nil)
        XCTAssertEqual(Result<Int?, Error>(success: nil, failure: TestError()).success, nil)
        XCTAssertNotNil(Result<Int?, Error>(success: nil as Int??, failure: TestError()).failure)
    }
    
    func test_Comparable_clamped() {
        XCTAssertEqual(5.clamped(to: 0 ... 10), 5)
        XCTAssertEqual(5.clamped(to: 5 ... 10), 5)
        XCTAssertEqual(5.clamped(to: 0 ... 5), 5)
        XCTAssertEqual(5.clamped(to: 5 ... 5), 5)
        
        XCTAssertEqual(5.clamped(to: 6 ... 10), 6)
        XCTAssertEqual(5.clamped(to: 0 ... 4), 4)
        
        XCTAssertEqual(5.clamped(to: -10 ... 0), 0)
        
        XCTAssertEqual(0.5.clamped(to: 0 ... 1.0), 0.5)
        XCTAssertEqual((-0.1).clamped(to: 0 ... 1.0), 0)
        XCTAssertEqual(1.1.clamped(to: 0 ... 1.0), 1)
    }
    
    func test_URL_ensureFileURL() throws {
        XCTAssertNoThrow(try URL(fileURLWithPath: "relative").ensureFileURL())
        XCTAssertNoThrow(try URL(fileURLWithPath: "/absolute").ensureFileURL())
        XCTAssertNoThrow(try URL(fileURLWithPath: "/absolute/dir").ensureFileURL())
        
        XCTAssertThrowsError(try URL(staticString: "https://remote.com").ensureFileURL())
    }
}
