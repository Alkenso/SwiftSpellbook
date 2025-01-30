//
//  RGBColor.swift
//  SwiftSpellbook
//
//  Created by Alkenso (Vladimir Vashurkin) on 2025-01-30.
//

import CoreGraphics

#if canImport(CoreGraphics)

public struct RGBColor: Hashable, Codable {
    public var red: CGFloat
    public var green: CGFloat
    public var blue: CGFloat
    public var alpha: CGFloat
    
    public init(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat = 1.0) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
}

extension RGBColor {
    public var cgColor: CGColor {
        CGColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}

extension RGBColor {
    public static func random(
        red: ClosedRange<CGFloat> = 0...1,
        green: ClosedRange<CGFloat> = 0...1,
        blue: ClosedRange<CGFloat> = 0...1
    ) -> RGBColor {
        .init(red: .random(in: red), green: .random(in: green), blue: .random(in: blue))
    }
}

#endif
