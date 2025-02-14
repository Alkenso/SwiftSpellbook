@testable import SpellbookFoundation

import XCTest

class GUITests: XCTestCase {
    func test_CGRect_center() {
        XCTAssertEqual(
            CGRect(x: 20, y: 40, width: 100, height: 200)
                .centered(against: CGRect(x: 60, y: 80, width: 400, height: 600)),
            CGRect(x: 210, y: 280, width: 100, height: 200)
        )
        
        XCTAssertEqual(
            CGRect(x: 20, y: 40, width: 400, height: 600)
                .centered(against: CGRect(x: 60, y: 80, width: 100, height: 200)),
            CGRect(x: -90, y: -120, width: 400, height: 600)
        )
    }
    
    func test_CGRect_flip() {
        let rect = CGRect(x: 20, y: 40, width: 100, height: 200)
        XCTAssertEqual(
            rect.flippedY(fullHeight: 400),
            CGRect(x: 20, y: 160, width: 100, height: 200)
        )
        XCTAssertEqual(
            rect.flippedY(fullHeight: 100),
            CGRect(x: 20, y: -140, width: 100, height: 200)
        )
        
        XCTAssertEqual(rect.flippedY(fullHeight: 400).flippedY(fullHeight: 400), rect)
    }
    
    func test_RGBColor() {
        XCTAssertEqual(RGBColor(hex: ""), nil)
        XCTAssertEqual(RGBColor(hex: "#"), nil)
        XCTAssertEqual(RGBColor(hex: "#FFF"), nil)
        XCTAssertEqual(RGBColor(hex: "#AABBCCDDE"), nil)
        XCTAssertEqual(RGBColor(hex: "#AABBCCE"), nil)
        
        XCTAssertEqual(RGBColor(hex: "#66FFCC"), RGBColor(red: 0x66 / 255.0, green: 1.0, blue: 0xCC / 255.0))
        XCTAssertEqual(RGBColor(hex: "66FFCC"), RGBColor(red: 0x66 / 255.0, green: 1.0, blue: 0xCC / 255.0))
        XCTAssertEqual(RGBColor(hex: "#66FFCC", alphaFirst: true), RGBColor(red: 0x66 / 255.0, green: 1.0, blue: 0xCC / 255.0))
        
        XCTAssertEqual(RGBColor(hex: "#66FFCC80"), RGBColor(red: 0x66 / 255.0, green: 1.0, blue: 0xCC / 255.0, alpha: 0x80 / 255.0))
        XCTAssertEqual(RGBColor(hex: "66FFCC80"), RGBColor(red: 0x66 / 255.0, green: 1.0, blue: 0xCC / 255.0, alpha: 0x80 / 255.0))
        XCTAssertEqual(RGBColor(hex: "#8066FFCC", alphaFirst: true), RGBColor(red: 0x66 / 255.0, green: 1.0, blue: 0xCC / 255.0, alpha: 0x80 / 255.0))
    }
}
