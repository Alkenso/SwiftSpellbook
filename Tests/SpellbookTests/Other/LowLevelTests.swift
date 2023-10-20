#if os(macOS)
    import SpellbookFoundation
    import XCTest
    
    class AuditTokenTests: XCTestCase {
        func test_currentTaskAuditToken() throws {
            let token = try audit_token_t.current()
            
            XCTAssertEqual(audit_token_to_ruid(token), getuid())
            XCTAssertEqual(audit_token_to_rgid(token), getgid())
            XCTAssertEqual(audit_token_to_euid(token), geteuid())
            XCTAssertEqual(audit_token_to_egid(token), getegid())
            XCTAssertEqual(audit_token_to_pid(token), getpid())
            XCTAssertNotEqual(audit_token_to_auid(token), 0)
            XCTAssertNotEqual(audit_token_to_asid(token), 0)
            XCTAssertNotEqual(audit_token_to_pidversion(token), 0)
        }
        
        func test_equals() {
            let token1 = audit_token_t(val: (UInt32(1), UInt32(1), UInt32(1), UInt32(1), UInt32(1), UInt32(1), UInt32(1), UInt32(1)))
            let token2 = audit_token_t(val: (UInt32(1), UInt32(1), UInt32(1), UInt32(1), UInt32(1), UInt32(1), UInt32(1), UInt32(1)))
            let token3 = audit_token_t(val: (UInt32(2), UInt32(1), UInt32(1), UInt32(1), UInt32(1), UInt32(1), UInt32(1), UInt32(1)))
            
            XCTAssertEqual(token1, token2)
            XCTAssertNotEqual(token1, token3)
        }
        
        func test_codable() throws {
            let token = audit_token_t(val: (UInt32(1), UInt32(2), UInt32(3), UInt32(4), UInt32(5), UInt32(6), UInt32(7), UInt32(8)))
            
            let data = try JSONEncoder().encode(token)
            let decodedToken = try JSONDecoder().decode(audit_token_t.self, from: data)
            XCTAssertEqual(decodedToken, token)
        }
    }
    
#endif
