//
//  File.swift
//  
//
//  Created by Alkenso (Vladimir Vashurkin) on 20.11.2021.
//

import SwiftConvenience
import XCTest


class ObjCTests: XCTestCase {
    func test_catchNSException() throws {
        let exception = NSException.catching {
            NSException(name: .genericException, reason: "Just", userInfo: nil).raise()
        }
        XCTAssertEqual(exception?.name, .genericException)
        XCTAssertEqual(exception?.reason, "Just")
    }
}
