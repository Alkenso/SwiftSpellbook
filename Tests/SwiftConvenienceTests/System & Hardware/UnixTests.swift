import SwiftConvenience

import XCTest

class UnixUserTests: XCTestCase {
    func test_currentUser() throws {
        guard let user = UnixUser(uid: getuid()) else {
            XCTFail("Failed to obtain user for uid = \(getuid())")
            return
        }
        
        XCTAssertEqual(user.uid, getuid())
        XCTAssertEqual(user.gid, getgid())
        
        XCTAssertGreaterThan(user.name.count, 0)
        XCTAssertGreaterThan(user.dir.count, 0)
        XCTAssertGreaterThan(user.shell.count, 0)
    }
    
    func test_currentUserGroups() throws {
        guard let user = UnixUser(uid: getuid()) else {
            XCTFail("Failed to obtain user for uid = \(getuid())")
            return
        }
        
        XCTAssertGreaterThan(user.allGroups.count, 2)
    }
    
    func test_root() throws {
        guard let user = UnixUser(uid: 0) else {
            XCTFail("Failed to obtain user for root user)")
            return
        }
        
        let groups = user.allGroups
        XCTAssertTrue(groups.contains(0))
        XCTAssertTrue(groups.contains(1))
        XCTAssertTrue(groups.contains(80))
    }
}

class UnixGroupTests: XCTestCase {
    func test_standardGroups() throws {
        XCTAssertEqual(UnixGroup(gid: 0)?.name, "wheel")
        XCTAssertEqual(UnixGroup(gid: 20)?.name, "staff")
        XCTAssertEqual(UnixGroup(gid: 80)?.name, "admin")
    }
}
