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

import CoreGraphics
import Foundation

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
