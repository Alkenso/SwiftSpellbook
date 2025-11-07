//
//  RGBColor.swift
//  SwiftSpellbook
//
//  Created by Alkenso (Vladimir Vashurkin) on 2025-01-30.
//

import SpellbookFoundation

import CoreGraphics

public struct RGBColor: Hashable, Codable, Sendable, ValueBuilder {
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

extension RGBColor {
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
        
        self.init(red: r, green: g, blue: b, alpha: a ?? 1.0)
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
        blue: ClosedRange<CGFloat> = 0...1
    ) -> RGBColor {
        .init(red: .random(in: red), green: .random(in: green), blue: .random(in: blue))
    }
    
    public static let white = RGBColor(red: 1, green: 1, blue: 1)
    public static let black = RGBColor(red: 0, green: 0, blue: 0)
    public static func gray(_ value: CGFloat) -> RGBColor { .init(red: value, green: value, blue: value) }
    
    public func emulatingOpacity(_ opacity: CGFloat) -> RGBColor {
        let newR = red * opacity + (1 - opacity)
        let newG = green * opacity + (1 - opacity)
        let newB = blue * opacity + (1 - opacity)
        return .init(red: newR, green: newG, blue: newB)
    }
}

#if canImport(AppKit)

import AppKit

extension RGBColor {
    public init(_ nsColor: NSColor) {
        self.init(
            red: nsColor.redComponent,
            green: nsColor.greenComponent,
            blue: nsColor.blueComponent,
            alpha: nsColor.alphaComponent
        )
    }
    
    public var nsColor: NSColor { NSColor(red: red, green: green, blue: blue, alpha: alpha) }
}

#endif

#if canImport(UIKit)

import UIKit

extension RGBColor {
    public init?(_ uiColor: UIColor) {
        self.init(cgColor: uiColor.cgColor)
    }
    
    public var uiColor: UIColor { UIColor(red: red, green: green, blue: blue, alpha: alpha) }
}

#endif

#if canImport(SwiftUI)

import SwiftUI

extension RGBColor {
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    public var suiColor: Color { Color(cgColor: cgColor) }
}

#endif
