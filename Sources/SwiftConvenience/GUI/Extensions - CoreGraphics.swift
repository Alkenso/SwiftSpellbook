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
    public func centered(against rect: CGRect) -> CGRect {
        var centeredOrigin = origin
        centeredOrigin.x = rect.origin.x + (rect.width / 2) - (width / 2)
        centeredOrigin.y = rect.origin.y + (rect.height / 2) - (height / 2)
        
        return CGRect(origin: centeredOrigin, size: size)
    }
    
    public mutating func center(against rect: CGRect) {
        self = centered(against: rect)
    }
}

#if os(macOS)

public struct CGWindowInfo {
    /// The window ID, a unique value within the user session representing the window (kCGWindowNumber).
    public var windowNumber: CGWindowID
    
    /// The bounds of the window in screen space, with the origin at the
    /// upper-left corner of the main display (kCGWindowBounds).
    public var frame: CGRect
    
    /// The process ID of the process that owns the window (kCGWindowOwnerPID).
    public var ownerPID: pid_t
    
    /// The name of the window (kCGWindowName).
    public var name: String?

    /// The name of the application process which owns the window (kCGWindowOwnerName).
    public var ownerName: String?
    
    /// If the window is ordered on screen (kCGWindowIsOnscreen).
    public var isOnscreen: Bool
    
    /// The window layer number of the window (kCGWindowLayer).
    public var windowLayer: Int
    
    /// The backing store type of the window (kCGWindowStoreType).
    public var backingStore: CGWindowBackingType

    /// The sharing state of the window (kCGWindowSharingState).
    public var sharingState: CGWindowSharingType

    /// The alpha fade of the window (kCGWindowAlpha).
    public var alpha: Double

    /// An estimate of the memory in bytes currently used by the window and its
    /// supporting data structures (kCGWindowMemoryUsage).
    public var memoryUsage: Int

    /// If the window backing store is in video memory (kCGWindowBackingLocationVideoMemory).
    public var backingLocationVideoMemory: Bool
    
    public init(
        windowNumber: CGWindowID, frame: CGRect, ownerPID: pid_t,
        name: String?, ownerName: String?,
        isOnscreen: Bool, windowLayer: Int,
        backingStore: CGWindowBackingType, sharingState: CGWindowSharingType,
        alpha: Double, memoryUsage: Int, backingLocationVideoMemory: Bool
    ) {
        self.windowNumber = windowNumber
        self.frame = frame
        self.ownerPID = ownerPID
        self.name = name
        self.ownerName = ownerName
        self.isOnscreen = isOnscreen
        self.windowLayer = windowLayer
        self.backingStore = backingStore
        self.sharingState = sharingState
        self.alpha = alpha
        self.memoryUsage = memoryUsage
        self.backingLocationVideoMemory = backingLocationVideoMemory
    }
}

extension CGWindowInfo {
    public static func list(_ options: CGWindowListOption, relativeToWindow: CGWindowID? = nil) -> [CGWindowInfo] {
        guard let list = CGWindowListCopyWindowInfo(options, relativeToWindow ?? kCGNullWindowID) else { return [] }
        guard let windowDescriptions = list as? [[CFString: Any]] else { return [] }
        
        let windows: [CGWindowInfo] = windowDescriptions.compactMap {
            guard let windowNumber = $0[kCGWindowNumber] as? CGWindowID,
                  let backingStore = ($0[kCGWindowStoreType] as? UInt32).flatMap(CGWindowBackingType.init(rawValue:)),
                  let windowLayer = $0[kCGWindowLayer] as? Int,
                  let frameDict = $0[kCGWindowBounds] as? NSDictionary as CFDictionary?,
                  let frame = CGRect(dictionaryRepresentation: frameDict),
                  let sharingState = ($0[kCGWindowSharingState] as? UInt32).flatMap(CGWindowSharingType.init(rawValue:)),
                  let alpha = $0[kCGWindowAlpha] as? Double,
                  let ownerPID = $0[kCGWindowOwnerPID] as? pid_t,
                  let memoryUsage = $0[kCGWindowMemoryUsage] as? Int
            else {
                return nil
            }
            return CGWindowInfo(
                windowNumber: windowNumber, frame: frame, ownerPID: ownerPID,
                name: $0[kCGWindowName] as? String,
                ownerName: $0[kCGWindowOwnerName] as? String,
                isOnscreen: $0[kCGWindowIsOnscreen] as? Bool ?? false,
                windowLayer: windowLayer,
                backingStore: backingStore,
                sharingState: sharingState,
                alpha: alpha, memoryUsage: memoryUsage,
                backingLocationVideoMemory: $0[kCGWindowBackingLocationVideoMemory] as? Bool ?? false
            )
        }
        
        return windows
    }
}

#endif
