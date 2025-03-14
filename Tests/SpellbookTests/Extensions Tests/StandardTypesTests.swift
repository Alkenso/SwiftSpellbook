import SpellbookFoundation
import SpellbookTestUtils

import XCTest

class ResultExtensionsTests: XCTestCase {
    func test_success_failure() {
        let resultWithValue: Result<Bool, Error> = .success(true)
        XCTAssertEqual(resultWithValue.success, true)
        XCTAssertNil(resultWithValue.failure)
        
        let resultWithError: Result<Bool, Error> = .failure(TestError())
        XCTAssertNil(resultWithError.success)
        XCTAssertNotNil(resultWithError.failure)
    }
    
    func test_initSuccessFailure() {
        XCTAssertEqual(Result<Int, Error>(success: 10, failure: nil).success, 10)
        XCTAssertNotNil(Result<Int, Error>(success: nil, failure: TestError()).failure)
        XCTAssertNotNil(Result<Int, Error>(success: nil, failure: nil).failure)
        
        XCTAssertEqual(Result<Int, Error>(success: 10, failure: TestError()).success, 10)
        
        //  Special case when Success == Optional
        XCTAssertEqual(Result<Int?, Error>(success: nil, failure: nil).success, nil)
        XCTAssertEqual(Result<Int?, Error>(success: nil, failure: TestError()).success, nil)
        XCTAssertNotNil(Result<Int?, Error>(success: nil as Int??, failure: TestError()).failure)
    }
}

class DataExtensionsTests: XCTestCase {
    private let tmp = TemporaryDirectory()
    
    override func setUpWithError() throws {
        try tmp.setUp()
    }
    
    override func tearDownWithError() throws {
        try tmp.tearDown()
    }
    
    func test_PODTypes_toData() {
        XCTAssertEqual(Data(pod: 0x10ff20), Data([0x20, 0xff, 0x10, 0x00, 0x00, 0x00, 0x00, 0x00]))
        XCTAssertEqual(Data(pod: 0), Data([0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]))
    }
    
    func test_PODTypes_exactly() {
        XCTAssertEqual(Data(pod: 0x10ff20), Data([0x20, 0xff, 0x10, 0x00, 0x00, 0x00, 0x00, 0x00]))
        XCTAssertEqual(Data(pod: 0), Data([0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]))
        
        XCTAssertEqual(Data([0x20, 0xff, 0x10, 0x00, 0x00, 0x00, 0x00, 0x00]).pod(exactly: Int.self), 0x10ff20)
        XCTAssertEqual(Data([0x20, 0xff, 0x10, 0x00]).pod(exactly: Int32.self), 0x10ff20)
        XCTAssertEqual(Data([0x20, 0xff, 0x10, 0x00]).pod(exactly: Int64.self), nil)
    }
    
    func test_PODTypes_adopting() {
        XCTAssertEqual(Data([0x20, 0xff, 0x10, 0x00, 0x00, 0x00, 0x00, 0x00]).pod(adopting: Int.self), 0x10ff20)
        XCTAssertEqual(Data([0x20, 0xff, 0x10]).pod(adopting: Int32.self), 0x10ff20)
        XCTAssertEqual(Data([0x20, 0xff, 0x10]).pod(adopting: Int64.self), 0x10ff20)
    }
    
    func test_fromHexString() {
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
    
    func test_toHexString() {
        XCTAssertEqual(
            Data([0x00, 0x01, 0x10, 0x0a, 0xa0, 0xff, 0x00]).hexString.uppercased(),
            "0001100AA0FF00"
        )
        XCTAssertEqual(
            Data().hexString,
            ""
        )
    }
    
    func test_contentsOfIfExists() throws {
        let nonexistentFile = "/\(UUID().uuidString)"
        let emptyFile = try tmp.createFile(name: "f1", content: Data())
        let nonemptyFile = try tmp.createFile(name: "f2", content: Data(pod: 123))
        
        let ifNoFile = Data(pod: 2)
        XCTAssertEqual(try Data(contentsOfFile: nonexistentFile, ifNoFile: ifNoFile), ifNoFile)
        XCTAssertEqual(try Data(contentsOf: emptyFile, ifNoFile: ifNoFile), Data())
        XCTAssertEqual(try Data(contentsOf: nonemptyFile, ifNoFile: ifNoFile), Data(pod: 123))
        
        XCTAssertThrowsError(try Data(contentsOfFile: "/etc/sudoers")) // No such file.
        XCTAssertThrowsError(try Data(contentsOfFile: "/etc/sudoers", ifNoFile: Data())) // Permissions denied.
    }
}

class ComparableExtensionsTests: XCTestCase {
    func test_clamped() {
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
    
    func test_relation() {
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
}

class URLExtensionsTests: XCTestCase {
    func test_ensureFileURL() throws {
        XCTAssertNoThrow(try URL(fileURLWithPath: "relative").ensureFileURL())
        XCTAssertNoThrow(try URL(fileURLWithPath: "/absolute").ensureFileURL())
        XCTAssertNoThrow(try URL(fileURLWithPath: "/absolute/dir").ensureFileURL())
        
        XCTAssertThrowsError(try URL(staticString: "https://remote.com").ensureFileURL())
    }
    
    func test_ensureFileExists() throws {
        XCTAssertThrowsError(try URL(fileURLWithPath: "relative").ensureFileExists())
        XCTAssertThrowsError(try URL(fileURLWithPath: "/absolute").ensureFileExists())
        XCTAssertThrowsError(try URL(fileURLWithPath: "/absolute/dir").ensureFileExists())
        XCTAssertThrowsError(try URL(staticString: "https://remote.com").ensureFileExists())
        
        XCTAssertNoThrow(try FileManager.default.homeDirectoryForCurrentUser.ensureFileURL())
        XCTAssertNoThrow(try testBundle.bundleURL.ensureFileURL())
        XCTAssertNoThrow(try testBundle.executableURL?.ensureFileURL())
    }
}

class UUIDExtensionsTests: XCTestCase {
    func test_zero() {
        XCTAssertEqual(UUID.zero.uuidString, "00000000-0000-0000-0000-000000000000")
    }
}

class StringExtensionsTests: XCTestCase {
    func test_parseKeyValuePair() throws {
        XCTAssertThrowsError(try "".parseKeyValuePair(separator: ""))
        XCTAssertThrowsError(try "keyvalue".parseKeyValuePair(separator: "="))
        XCTAssertEqual(try "key=value".parseKeyValuePair(separator: "="), KeyValue("key", "value"))
        
        XCTAssertThrowsError(try "key=value=1".parseKeyValuePair(separator: "="))
        XCTAssertEqual(try "key=value=1".parseKeyValuePair(separator: "=", allowSeparatorsInValue: true), KeyValue("key", "value=1"))
        XCTAssertThrowsError(try "keyvalue".parseKeyValuePair(separator: "=", allowSeparatorsInValue: true))
    }
    
    func test_parseKeyValuePairs() throws {
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
}

class DateTimeExtensionsTests: XCTestCase {
    func test_Date_fromTimespec() {
        let ts = timespec(tv_sec: 123, tv_nsec: 456)
        XCTAssertEqual(Date(ts: ts).timeIntervalSince1970, 123.000000456, accuracy: 100 / Double(NSEC_PER_SEC))
        
        let ts2 = timespec(tv_sec: 5_000_000_000, tv_nsec: 456)
        XCTAssertEqual(Date(ts: ts2).timeIntervalSince1970, 5_000_000_000.000000456, accuracy: 100 / Double(NSEC_PER_SEC))
        
        let ts3 = timespec(tv_sec: 123, tv_nsec: 990_000_000)
        XCTAssertEqual(Date(ts: ts3).timeIntervalSince1970, 123.990000000, accuracy: 100 / Double(NSEC_PER_SEC))
    }
    
    func test_TimeInterval_fromTimespec() {
        let ts = timespec(tv_sec: 123, tv_nsec: 456)
        XCTAssertEqual(ts.timeInterval, 123.000000456, accuracy: 1 / Double(NSEC_PER_SEC))
        
        let ts2 = timespec(tv_sec: 5_000_000_000, tv_nsec: 456)
        XCTAssertEqual(ts2.timeInterval, 5_000_000_000.000000456, accuracy: 1 / Double(NSEC_PER_SEC))
        
        let ts3 = timespec(tv_sec: 123, tv_nsec: 990_000_000)
        XCTAssertEqual(ts3.timeInterval, 123.990000000, accuracy: 1 / Double(NSEC_PER_SEC))
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
}

class OptionalExtensionsTests: XCTestCase {
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
    
    func test_unwrapSafely() {
        let error: Error? = TestError()
        let unwrapped = error.safelyUnwrapped
        XCTAssertNotNil(unwrapped as? TestError)
        
        let nilError: Error? = nil
        let unwrappedNil = nilError.safelyUnwrapped
        XCTAssertNotNil(unwrappedNil as? CommonError)
    }
    
    func test_Optional_coalesce() {
        var value: Int? = nil
        XCTAssertEqual(value.coalesce(10), 10)
        XCTAssertEqual(value, 10)
        
        XCTAssertEqual(value.coalesce(5), 10)
        XCTAssertEqual(value, 10)
    }
    
    func test_Optional_noneIf() {
        XCTAssertNotNil(Int?.noneIf(5, equals: nil))
        XCTAssertNotNil(Int?.noneIf(5, equals: 3))
        
        XCTAssertNil(Int?.noneIf(nil, equals: 5))
        XCTAssertNil(Int?.noneIf(5, equals: 5))
        
        struct Foo {
            var a: Int
            var b: Int
        }
        
        let foo = Foo(a: 5, b: 10)
        XCTAssertNotNil(Foo?.noneIf(foo, at: \.a, equals: nil))
        XCTAssertNotNil(Foo?.noneIf(foo, at: \.a, equals: 3))
        
        XCTAssertNil(Foo?.noneIf(nil, at: \.a, equals: 5))
        XCTAssertNil(Foo?.noneIf(foo, at: \.a, equals: 5))
    }
}
