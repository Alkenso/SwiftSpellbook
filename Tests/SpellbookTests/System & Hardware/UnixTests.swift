#if os(macOS)

import SpellbookFoundation

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
        XCTAssertEqual(user.isLoggedIn, true)
        XCTAssertEqual(user.hasAccount, true)
        
        XCTAssertTrue(UnixUser.allUsers.contains { $0.uid == getuid() })
    }
    
    func test_currentUserGroups() throws {
        guard let user = UnixUser(uid: getuid()) else {
            XCTFail("Failed to obtain user for uid = \(getuid())")
            return
        }
        
        XCTAssertGreaterThan(try user.allGroups().count, 2)
    }
    
    func test_root() throws {
        guard let user = UnixUser(uid: 0) else {
            XCTFail("Failed to obtain user for root user)")
            return
        }
        
        let groups = try user.allGroups()
        XCTAssertTrue(groups.contains { $0.gid == UnixGroup.wheel.gid })
        XCTAssertTrue(groups.contains { $0.gid == UnixGroup.staff.gid })
        XCTAssertTrue(groups.contains { $0.gid == UnixGroup.admin.gid })
    }
}

class UnixGroupTests: XCTestCase {
    func test_allGroups() throws {
        let groups = UnixGroup.allGroups
        
        XCTAssertTrue(groups.contains { $0.gid == UnixGroup.wheel.gid })
        XCTAssertTrue(groups.contains { $0.gid == UnixGroup.staff.gid })
        XCTAssertTrue(groups.contains { $0.gid == UnixGroup.admin.gid })
    }
    
    func test_standardGroups() throws {
        XCTAssertEqual(UnixGroup(gid: 0)?.name, "wheel")
        XCTAssertEqual(UnixGroup(gid: 20)?.name, "staff")
        XCTAssertEqual(UnixGroup(gid: 80)?.name, "admin")
    }
}

#endif
