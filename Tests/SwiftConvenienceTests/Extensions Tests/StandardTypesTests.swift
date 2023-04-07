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
    
    func test_Error_xpcCompatible() {
        let compatibleError = NSError(domain: "test", code: 1, userInfo: [
            "compatible_key": "compatible_value",
            "compatible_key2": ["value1", "value2"],
        ])
        // No conversion.
        XCTAssertTrue(compatibleError === (compatibleError.xpcCompatible() as NSError))
        
        struct SwiftType {}
        let error = NSError(domain: "test", code: 1, userInfo: [
            "compatible_key": "compatible_value",
            "incompatible_key": SwiftType(),
            "maybe_incompatible_key": UUID(),
        ])
        
        XCTAssertThrowsError(try NSKeyedArchiver.archivedData(withRootObject: error, requiringSecureCoding: true))
        
        let xpcCompatible = error.xpcCompatible()
        XCTAssertNoThrow(try NSKeyedArchiver.archivedData(withRootObject: xpcCompatible, requiringSecureCoding: true))
    }
    
    func test_Result_success_failure() {
        let resultWithValue: Result<Bool, Error> = .success(true)
        XCTAssertEqual(resultWithValue.success, true)
        XCTAssertNil(resultWithValue.failure)
        
        let resultWithError: Result<Bool, Error> = .failure(TestError())
        XCTAssertNil(resultWithError.success)
        XCTAssertNotNil(resultWithError.failure)
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
    
    func test_Comparable_relation() {
        XCTAssertFalse(10.compare(to: 9, relation: .equal))
        XCTAssertTrue(10.compare(to: 10, relation: .equal))
        XCTAssertFalse(10.compare(to: 11, relation: .equal))
        
        XCTAssertFalse(10.compare(to: 9, relation: .lessThan))
        XCTAssertFalse(10.compare(to: 10, relation: .lessThan))
        XCTAssertTrue(10.compare(to: 11, relation: .lessThan))
        
        XCTAssertFalse(10.compare(to: 9, relation: .lessThanOrEqual))
        XCTAssertTrue(10.compare(to: 10, relation: .lessThanOrEqual))
        XCTAssertTrue(10.compare(to: 11, relation: .lessThanOrEqual))
        
        XCTAssertTrue(10.compare(to: 9, relation: .greaterThan))
        XCTAssertFalse(10.compare(to: 10, relation: .greaterThan))
        XCTAssertFalse(10.compare(to: 11, relation: .greaterThan))
        
        XCTAssertTrue(10.compare(to: 9, relation: .greaterThanOrEqual))
        XCTAssertTrue(10.compare(to: 10, relation: .greaterThanOrEqual))
        XCTAssertFalse(10.compare(to: 11, relation: .greaterThanOrEqual))
    }
    
    func test_URL_ensureFileURL() throws {
        XCTAssertNoThrow(try URL(fileURLWithPath: "relative").ensureFileURL())
        XCTAssertNoThrow(try URL(fileURLWithPath: "/absolute").ensureFileURL())
        XCTAssertNoThrow(try URL(fileURLWithPath: "/absolute/dir").ensureFileURL())
        
        XCTAssertThrowsError(try URL(staticString: "https://remote.com").ensureFileURL())
    }
    
    func test_UUID_zero() {
        XCTAssertEqual(UUID.zero.uuidString, "00000000-0000-0000-0000-000000000000")
    }
    
    func test_String_parseKeyValuePair() throws {
        XCTAssertThrowsError(try "".parseKeyValuePair(separator: ""))
        XCTAssertThrowsError(try "keyvalue".parseKeyValuePair(separator: "="))
        XCTAssertEqual(try "key=value".parseKeyValuePair(separator: "="), KeyValue("key", "value"))
        
        XCTAssertThrowsError(try "key=value=1".parseKeyValuePair(separator: "="))
        XCTAssertEqual(try "key=value=1".parseKeyValuePair(separator: "=", allowSeparatorsInValue: true), KeyValue("key", "value=1"))
        XCTAssertThrowsError(try "keyvalue".parseKeyValuePair(separator: "=", allowSeparatorsInValue: true))
    }
    
    func test_String_parseKeyValuePairs() throws {
        XCTAssertThrowsError(try "".parseKeyValuePairs(keyValue: "", pairs: ""))
        XCTAssertThrowsError(try "".parseKeyValuePairs(keyValue: "=", pairs: ""))
        XCTAssertThrowsError(try "".parseKeyValuePairs(keyValue: "", pairs: "="))
        
        XCTAssertThrowsError(try "keyvalue,keyvalue2".parseKeyValuePairs(keyValue: "=", pairs: ","))
        XCTAssertThrowsError(try "key=valuekey=value2".parseKeyValuePairs(keyValue: "=", pairs: ","))
        
        XCTAssertEqual(
            try "key1=value1,key1=value2,key3=value3".parseKeyValuePairs(keyValue: "=", pairs: ","),
            [KeyValue("key1", "value1"), KeyValue("key1", "value2"), KeyValue("key3", "value3")]
        )
    }
    
    func test_TimeInterval_fromTimespec() {
        let ts = timespec(tv_sec: 123, tv_nsec: 456)
        XCTAssertEqual(TimeInterval(ts: ts), 123.000000456, accuracy: 1 / Double(NSEC_PER_SEC))
        
        let ts2 = timespec(tv_sec: 5_000_000_000, tv_nsec: 456)
        XCTAssertEqual(TimeInterval(ts: ts2), 5_000_000_000.000000456, accuracy: 1 / Double(NSEC_PER_SEC))
        
        let ts3 = timespec(tv_sec: 123, tv_nsec: 990_000_000)
        XCTAssertEqual(TimeInterval(ts: ts3), 123.990000000, accuracy: 1 / Double(NSEC_PER_SEC))
    }
    
    func test_Date_fromTimespec() {
        let ts = timespec(tv_sec: 123, tv_nsec: 456)
        XCTAssertEqual(Date(ts: ts).timeIntervalSince1970, 123.000000456, accuracy: 100 / Double(NSEC_PER_SEC))
        
        let ts2 = timespec(tv_sec: 5_000_000_000, tv_nsec: 456)
        XCTAssertEqual(Date(ts: ts2).timeIntervalSince1970, 5_000_000_000.000000456, accuracy: 100 / Double(NSEC_PER_SEC))
        
        let ts3 = timespec(tv_sec: 123, tv_nsec: 990_000_000)
        XCTAssertEqual(Date(ts: ts3).timeIntervalSince1970, 123.990000000, accuracy: 100 / Double(NSEC_PER_SEC))
    }
    
    func test_Calendar_endOfDay() {
        // GMT: Friday, 7 April 2023 y., 10:46:19
        let date = Date(timeIntervalSince1970: 1680864379)
        let dayEnd = Calendar.iso8601UTC.endOfDay(for: date)
        
        // GMT: Friday, 7 April 2023 y., 23:59:59.999
        XCTAssertEqual(
            dayEnd.timeIntervalSince1970,
            Date(timeIntervalSince1970: 1680911999.999).timeIntervalSince1970,
            accuracy: 0.0001
        )
        
        // GMT: Saturday, 8 April 2023 y., 00:00:00
        XCTAssertLessThan(dayEnd, Date(timeIntervalSince1970: 1680912000))
    }
    
    func test_Optional_default() {
        var value: Int? = nil
        XCTAssertEqual(value[default: 10], 10)
        
        value[default: 10] = 5
        XCTAssertEqual(value[default: 10], 5)
        
        struct Stru {
            var value: Int?
        }
        var dict: [String: Stru] = ["key": Stru()]
        dict["key"]?.value[default: 10] += 1
        XCTAssertEqual(dict["key"]?.value, 11)
    }
}
