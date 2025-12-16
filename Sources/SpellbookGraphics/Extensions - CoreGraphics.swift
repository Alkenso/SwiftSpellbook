//  MIT License
//
//  Copyright (c) 2022 Alkenso (Vladimir Vashurkin)
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
import Foundation
import ImageIO
import UniformTypeIdentifiers

extension CGPoint {
    public mutating func scale(_ scale: CGFloat) {
        self = scaled(scale)
    }
    
    public func scaled(_ scale: CGFloat) -> CGPoint {
        CGPoint(x: x * scale, y: y * scale)
    }
}

extension CGPoint: @retroactive AdditiveArithmetic {
    public static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
    
    public static func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
}

extension CGPoint {
    public static func + (lhs: CGPoint, rhs: CGSize) -> CGPoint {
        CGPoint(x: lhs.x + rhs.width, y: lhs.y + rhs.height)
    }
    
    public static func += (lhs: inout CGPoint, rhs: CGSize) {
        lhs.x += rhs.width
        lhs.y += rhs.height
    }
    
    public static func - (lhs: CGPoint, rhs: CGSize) -> CGPoint {
        CGPoint(x: lhs.x - rhs.width, y: lhs.y - rhs.height)
    }
    
    public static func -= (lhs: inout CGPoint, rhs: CGSize) {
        lhs.x -= rhs.width
        lhs.y -= rhs.height
    }
}

extension CGSize {
    public static let unit = CGSize(width: 1, height: 1)
    
    public var area: CGFloat { width * height }
    
    public mutating func scale(_ scale: CGFloat) {
        self = scaled(scale)
    }
    
    public func scaled(_ scale: CGFloat) -> CGSize {
        CGSize(width: width * scale, height: height * scale)
    }
}

extension CGSize: @retroactive AdditiveArithmetic {
    public static func + (lhs: CGSize, rhs: CGSize) -> CGSize {
        CGSize(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
    }
    
    public static func - (lhs: CGSize, rhs: CGSize) -> CGSize {
        CGSize(width: lhs.width - rhs.width, height: lhs.height - rhs.height)
    }
}

extension CGRect {
    public static let unit = CGRect(x: 0, y: 0, width: 1, height: 1)
    
    public var center: CGPoint { CGPoint(x: midX, y: midY) }
    public var area: CGFloat { width * height }
    
    public init(origin: CGPoint, extent: CGPoint) {
        self.init(origin: origin, size: CGSize(width: extent.x - origin.x, height: extent.y - origin.y))
    }
    
    public var extent: CGPoint {
        get { .init(x: maxX, y: maxY) }
        set { size.width += newValue.x - maxX; size.height += newValue.y - maxY }
    }
    
    /// Center given rect relative to another one.
    /// - returns: New CGRect which center is the same with given one.
    public func centered(against rect: CGRect) -> CGRect {
        var centeredOrigin = origin
        centeredOrigin.x = rect.origin.x + (rect.width / 2) - (width / 2)
        centeredOrigin.y = rect.origin.y + (rect.height / 2) - (height / 2)
        
        return CGRect(origin: centeredOrigin, size: size)
    }
    
    /// Center given rect relative to another one.
    public mutating func center(against rect: CGRect) {
        self = centered(against: rect)
    }
    
    public func verticallyFlipped(fullHeight: CGFloat) -> CGRect {
        let newY = fullHeight - (origin.y + height)
        return CGRect(x: origin.x, y: newY, width: width, height: height)
    }
    
    public mutating func verticallyFlip(fullHeight: CGFloat) {
        self = verticallyFlipped(fullHeight: fullHeight)
    }
    
    public mutating func scale(_ scale: CGFloat) {
        self = scaled(scale)
    }
    
    public func scaled(_ scale: CGFloat) -> CGRect {
        CGRect(origin: origin.scaled(scale), size: size.scaled(scale))
    }
}

extension CGImage {
    /// Creates `Data` representation of the image.
    /// - Parameters:
    ///     - format: Desired format of the image representation.
    /// - Returns: `Data` in requested format or `nil` if error occurs.
    @available(macOS 11.0, iOS 14, tvOS 14.0, watchOS 7.0, *)
    public func representation(in format: UTType) -> Data? {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, format.identifier as CFString, 1, nil) else {
            return nil
        }
        
        CGImageDestinationAddImage(destination, self, nil)
        guard CGImageDestinationFinalize(destination) else { return nil }
        
        return data as Data
    }
    
    /// Creates `CGImage` from its representation.
    /// - Parameters:
    ///     - data: Binary representation data.
    /// - Returns: `CGImage` or `nil` if error occurs.
    public static func fromRepresentation(_ data: Data) -> CGImage? {
        guard let dataProvider = CGDataProvider(data: data as CFData) else { return nil }
        guard let source = CGImageSourceCreateWithDataProvider(dataProvider, nil) else { return nil }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }
    
    /// Writes image to the file on disk.
    /// - Parameters:
    ///     - url: Location on disk to write the image.
    ///     - format: Desired format of the image representation.
    ///     If `nil`, format is tried to be obtained from `url` path extension.
    /// - Returns: Boolean indicating the write succeeds.
    @available(macOS 11.0, iOS 14, tvOS 14.0, watchOS 7.0, *)
    public func writeToFile(_ url: URL, in format: UTType?) -> Bool {
        guard let format = format ?? UTType(filenameExtension: url.lastPathComponent, conformingTo: .image) else {
            return false
        }
        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL,
            format.identifier as CFString,
            1,
            nil
        ) else {
            return false
        }
        
        CGImageDestinationAddImage(destination, self, nil)
        guard CGImageDestinationFinalize(destination) else { return false }
        
        return true
    }
    
    /// Creates `CGImage` from file on disk.
    /// - Parameters:
    ///     - url: Location on disk to read the image from.
    /// - Returns: `CGImage` or `nil` if error occurs.
    public static func readFromFile(_ url: URL) -> CGImage? {
        guard let dataProvider = CGDataProvider(url: url as CFURL) else { return nil }
        guard let source = CGImageSourceCreateWithDataProvider(dataProvider, nil) else { return nil }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }
}
