import SpellbookFoundation

import XCTest

class NSErrorTests: XCTestCase {
    func test_errorBuilding_withDebugDescription() {
        XCTAssertEqual(
            NSError(posix: 0)
                .withDebugDescription("Description")
                .userInfo[NSDebugDescriptionErrorKey] as? String,
            "Description"
        )
        XCTAssertEqual(
            NSError(posix: 0)
                .withDebugDescription("Description")
                .withDebugDescription("Description 2")
                .userInfo[NSDebugDescriptionErrorKey] as? String,
            "Description 2"
        )
    }
    
    func test_errorBuilding_withUserInfoSingle() {
        XCTAssertEqual(
            NSError(posix: 0)
                .withUserInfo(10, for: "Key")
                .userInfo["Key"] as? Int,
            10
        )
        XCTAssertEqual(
            NSError(posix: 0)
                .withUserInfo(10, for: "Key")
                .withUserInfo(20, for: "Key")
                .userInfo["Key"] as? Int,
            20
        )
        
        let userInfo = NSError(posix: 0)
            .withUserInfo(10, for: "Key")
            .withUserInfo(20, for: "Key 2")
            .userInfo
        XCTAssertEqual(userInfo["Key"] as? Int, 10)
        XCTAssertEqual(userInfo["Key 2"] as? Int, 20)
    }
    
    func test_errorBuilding_withUserInfoMerged() {
        let error = NSError(posix: 0)
            .withUserInfo(10, for: "Key")
            .withUserInfo(20, for: "Key 2")
        
        let mergedUserInfo = error.withUserInfo([
            "Key": "Abc",
            "Key 3": 30,
        ]).userInfo
        
        XCTAssertEqual(mergedUserInfo["Key"] as? String, "Abc")
        XCTAssertEqual(mergedUserInfo["Key 2"] as? Int, 20)
        XCTAssertEqual(mergedUserInfo["Key 3"] as? Int, 30)
    }
    
    func test_errorBuilding_appendingUnderlyingError() {
        let underlyingError1 = NSError(domain: "Test 1", code: 1)
        let underlyingError2 = NSError(domain: "Test 2", code: 2)
        let underlyingError3 = NSError(domain: "Test 3", code: 3)
        
        let error1 = NSError(posix: 0).appendingUnderlyingError(underlyingError1)
        XCTAssertEqual((error1.userInfo[NSUnderlyingErrorKey] as? NSError)?.domain, "Test 1")
        XCTAssertEqual((error1.userInfo[NSUnderlyingErrorKey] as? NSError)?.code, 1)
        
        let error2 = NSError(posix: 0)
            .appendingUnderlyingError(underlyingError1)
            .appendingUnderlyingError(underlyingError2)
            .appendingUnderlyingError(underlyingError3)
        XCTAssertEqual((error2.userInfo[NSUnderlyingErrorKey] as? NSError)?.domain, "Test 1")
        XCTAssertEqual((error2.userInfo[NSUnderlyingErrorKey] as? NSError)?.code, 1)
        if let error2UnderlyingErrors = error2.userInfo[NSError.multipleUnderlyingErrorsKey] as? [NSError], error2UnderlyingErrors.count == 2 {
            XCTAssertEqual(error2UnderlyingErrors[0].domain, "Test 2")
            XCTAssertEqual(error2UnderlyingErrors[0].code, 2)
            
            XCTAssertEqual(error2UnderlyingErrors[1].domain, "Test 3")
            XCTAssertEqual(error2UnderlyingErrors[1].code, 3)
        } else {
            XCTFail("Invalid underlying errors")
        }
    }
}
