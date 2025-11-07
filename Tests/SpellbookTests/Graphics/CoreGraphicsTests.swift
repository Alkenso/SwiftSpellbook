import SpellbookGraphics

import XCTest

class CGPointTexts: XCTestCase {
    func test_scale() {
        let pt = CGPoint(x: 10, y: 10)
        XCTAssertEqual(pt.scaled(2), CGPoint(x: 20, y: 20))
    }
    
    func test_add() {
        let lhs = CGPoint(x: 10, y: 10)
        let rhs = CGPoint(x: 2, y: 4)
        XCTAssertEqual(lhs + rhs, CGPoint(x: 12, y: 14))
        XCTAssertEqual(lhs - rhs, CGPoint(x: 8, y: 6))
        XCTAssertEqual(lhs + rhs, rhs + lhs)
    }
}

class CGSizeTexts: XCTestCase {
    func test_scale() {
        let size = CGSize(width: 10, height: 10)
        XCTAssertEqual(size.scaled(2), CGSize(width: 20, height: 20))
    }
    
    func test_add() {
        let lhs = CGSize(width: 10, height: 10)
        let rhs = CGSize(width: 2, height: 4)
        XCTAssertEqual(lhs + rhs, CGSize(width: 12, height: 14))
        XCTAssertEqual(lhs - rhs, CGSize(width: 8, height: 6))
        XCTAssertEqual(lhs + rhs, rhs + lhs)
    }
    
    func test_unit() {
        XCTAssertEqual(.unit, CGSize(width: 1, height: 1))
    }
    
    func test_area() {
        XCTAssertEqual(CGSize(width: 10, height: 20).area, 200)
    }
}

class GGRectTests: XCTestCase {
    func test_center() {
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
    
    func test_flip() {
        let rect = CGRect(x: 20, y: 40, width: 100, height: 200)
        XCTAssertEqual(
            rect.verticallyFlipped(fullHeight: 400),
            CGRect(x: 20, y: 160, width: 100, height: 200)
        )
        XCTAssertEqual(
            rect.verticallyFlipped(fullHeight: 100),
            CGRect(x: 20, y: -140, width: 100, height: 200)
        )
        
        XCTAssertEqual(rect.verticallyFlipped(fullHeight: 400).verticallyFlipped(fullHeight: 400), rect)
    }
    
    func test_scale() {
        XCTAssertEqual(
            CGRect(x: 10, y: 20, width: 30, height: 40).scaled(2),
            CGRect(x: 20, y: 40, width: 60, height: 80)
        )
    }
    
    func test_area() {
        XCTAssertEqual(CGRect(x: 10, y: 20, width: 30, height: 40).area, 1200)
    }
    
    func test_misc() {
        XCTAssertEqual(.unit, CGRect(x: 0, y: 0, width: 1, height: 1))
        XCTAssertEqual(CGRect(x: 10, y: 20, width: 30, height: 40).extent, CGPoint(x: 40, y: 60))
        XCTAssertEqual(
            CGRect(origin: CGPoint(x: 10, y: 20), extent: CGPoint(x: 40, y: 60)),
            CGRect(x: 10, y: 20, width: 30, height: 40)
        )
    }
}

class RGBColorTests: XCTestCase {
    func test_hex() {
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
