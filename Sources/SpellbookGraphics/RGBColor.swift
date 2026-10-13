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

import SpellbookFoundation

import CoreGraphics

public struct RGBColor: Hashable, Codable, Sendable {
    public var red: CGFloat
    public var green: CGFloat
    public var blue: CGFloat
    public var alpha: CGFloat
    
    public init(
        @Clamped(0...1) red: CGFloat,
        @Clamped(0...1) green: CGFloat,
        @Clamped(0...1) blue: CGFloat,
        @Clamped(0...1) alpha: CGFloat = 1.0
    ) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
}

extension RGBColor: RGBColorInitializable {
    public init(rgb: RGBColor) {
        self = rgb
    }
}

extension RGBColor {
    public init?(cgColor: CGColor) {
        guard let rgb = cgColor.converted(
            to: CGColorSpaceCreateDeviceRGB(),
            intent: .defaultIntent,
            options: nil
        ) else { return nil }
        guard let components = rgb.components, components.count >= 3 else { return nil }
        self.init(red: components[0], green: components[1], blue: components[2], alpha: rgb.alpha)
    }
    
    public var cgColor: CGColor {
        CGColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}

extension RGBColor {
    public static func random(
        red: ClosedRange<CGFloat> = 0...1,
        green: ClosedRange<CGFloat> = 0...1,
        blue: ClosedRange<CGFloat> = 0...1,
    ) -> RGBColor {
        .init(red: .random(in: red), green: .random(in: green), blue: .random(in: blue))
    }
    
    public static let white = RGBColor(red: 1, green: 1, blue: 1)
    public static let black = RGBColor(red: 0, green: 0, blue: 0)
    public static func gray(_ value: CGFloat) -> RGBColor { .init(red: value, green: value, blue: value) }
    public static let red = RGBColor(red: 1, green: 0, blue: 0)
    public static let green = RGBColor(red: 0, green: 1, blue: 0)
    public static let blue = RGBColor(red: 0, green: 0, blue: 1)
    public static let yellow = RGBColor(red: 1, green: 1, blue: 0)
    public static let cyan = RGBColor(red: 0, green: 1, blue: 1)
    public static let magenta = RGBColor(red: 1, green: 0, blue: 1)
    
    public func emulatingOpacity(_ opacity: CGFloat) -> RGBColor {
        let opacity = opacity.clamped(to: 0...1) * alpha
        let newR = red * opacity + (1 - opacity)
        let newG = green * opacity + (1 - opacity)
        let newB = blue * opacity + (1 - opacity)
        return .init(red: newR, green: newG, blue: newB)
    }
}

#if canImport(AppKit)

import AppKit

extension RGBColor {
    /// Creates the color from `NSColor`.
    ///
    /// - Note: `NSColor` raises an exception when RGB components are accessed on a color
    /// that is not RGB-compatible (named, catalog or pattern colors).
    /// Such colors are converted to sRGB first. If the conversion is not possible,
    /// all components of the resulting color are set to zero.
    public init(_ nsColor: NSColor) {
        guard let rgb = nsColor.usingColorSpace(.sRGB) else {
            self.init(red: 0, green: 0, blue: 0, alpha: 0)
            return
        }
        self.init(
            red: rgb.redComponent,
            green: rgb.greenComponent,
            blue: rgb.blueComponent,
            alpha: rgb.alphaComponent
        )
    }
    
    public var nsColor: NSColor { NSColor(rgb: self) }
}

#endif

#if canImport(UIKit)

import UIKit

extension RGBColor {
    public init?(_ uiColor: UIColor) {
        self.init(cgColor: uiColor.cgColor)
    }
    
    public var uiColor: UIColor { UIColor(rgb: self) }
}

#endif

#if canImport(SwiftUI)

import SwiftUI

extension RGBColor {
    public var suiColor: Color { Color(cgColor: cgColor) }
}

#endif
