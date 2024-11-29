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

#if canImport(CoreGraphics)

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

extension CGRect {
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
    
    public func flippedY(fullHeight: CGFloat) -> CGRect {
        let newY = fullHeight - (origin.y + height)
        return CGRect(x: origin.x, y: newY, width: width, height: height)
    }
    
    public mutating func flipY(fullHeight: CGFloat) {
        self = flippedY(fullHeight: fullHeight)
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

#endif
