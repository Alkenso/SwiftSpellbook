#if os(macOS) && canImport(AppKit)

import AppKit

public typealias PlatformColor = NSColor
public typealias PlatformImage = NSImage
public typealias PlatformFont = NSFont
public typealias PlatformFontDescriptor = NSFontDescriptor
public typealias PlatformEdgeInsets = NSEdgeInsets

public typealias PlatformView = NSView
public typealias PlatformViewController = NSViewController

#elseif canImport(UIKit)

import UIKit

public typealias PlatformColor = UIColor
public typealias PlatformImage = UIImage
public typealias PlatformFont = UIFont
public typealias PlatformFontDescriptor = UIFontDescriptor
public typealias PlatformEdgeInsets = UIEdgeInsets

#if !os(watchOS)

public typealias PlatformView = UIView
public typealias PlatformViewController = UIViewController

#endif

#endif
