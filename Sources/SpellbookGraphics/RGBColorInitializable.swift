//  MIT License
//
//  Copyright (c) 2026 Alkenso (Vladimir Vashurkin)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import CoreGraphics

public protocol RGBColorInitializable {
    init(rgb: RGBColor)
}

extension RGBColorInitializable {
    public static func hex(rgb hex: UInt32, alpha: CGFloat = 1.0) -> Self {
        // 0xRRGGBB
        Self(rgb: RGBColor(
            red: component(hex >> 16),
            green: component(hex >> 8),
            blue: component(hex),
            alpha: alpha
        ))
    }
    
    public static func hex(rgba hex: UInt32) -> Self {
        // 0xRRGGBBAA
        Self(rgb: RGBColor(
            red: component(hex >> 24),
            green: component(hex >> 16),
            blue: component(hex >> 8),
            alpha: component(hex)
        ))
    }
    
    public static func hex(bgr hex: UInt32, alpha: CGFloat = 1.0) -> Self {
        // 0xBBGGRR
        Self(rgb: RGBColor(
            red: component(hex),
            green: component(hex >> 8),
            blue: component(hex >> 16),
            alpha: alpha
        ))
    }
    
    public static func hex(bgra hex: UInt32) -> Self {
        // 0xBBGGRRAA
        Self(rgb: RGBColor(
            red: component(hex >> 8),
            green: component(hex >> 16),
            blue: component(hex >> 24),
            alpha: component(hex)
        ))
    }
    
    // Extracts the lowest byte and normalizes it to 0...1
    private static func component(_ value: UInt32) -> CGFloat {
        CGFloat(value & 0xFF) / 255
    }
}

extension RGBColorInitializable {
    public init?(hex hexColor: String, alphaFirst: Bool = false) {
        var hexColor = hexColor
        if hexColor.hasPrefix("#") {
            hexColor.removeFirst()
        }
        
        let hasAlpha = hexColor.count == 8
        guard hexColor.count == 6 || hasAlpha else { return nil }
        
        func popColorComponent() -> CGFloat? {
            guard hexColor.count >= 2 else { return nil }
            
            let to = hexColor.index(hexColor.startIndex, offsetBy: 1)
            let str = hexColor[hexColor.startIndex...to]
            hexColor.removeFirst(2)
            
            let int = Int(str, radix: 16)
            return int.flatMap { CGFloat($0) / 255 }
        }
        
        var a: CGFloat?
        if hasAlpha, alphaFirst {
            a = popColorComponent()
        }
        guard let r = popColorComponent(),
              let g = popColorComponent(),
              let b = popColorComponent()
                else {
            return nil
        }
        if a == nil {
            a = popColorComponent()
        }
        
        self.init(rgb: RGBColor(red: r, green: g, blue: b, alpha: a ?? 1.0))
    }
}

extension CGColor: RGBColorInitializable {}

extension RGBColorInitializable where Self: CGColor {
    public init(rgb: RGBColor) {
        self.init(srgbRed: rgb.red, green: rgb.green, blue: rgb.blue, alpha: rgb.alpha)
    }
}

#if canImport(AppKit)

import AppKit

extension NSColor: RGBColorInitializable {}

extension RGBColorInitializable where Self: NSColor {
    public init(rgb: RGBColor) {
        self.init(srgbRed: rgb.red, green: rgb.green, blue: rgb.blue, alpha: rgb.alpha)
    }
}

#endif

#if canImport(UIKit)

import UIKit

extension UIColor: RGBColorInitializable {}

extension RGBColorInitializable where Self: UIColor {
    public init(rgb: RGBColor) {
        self.init(red: rgb.red, green: rgb.green, blue: rgb.blue, alpha: rgb.alpha)
    }
}

#endif
