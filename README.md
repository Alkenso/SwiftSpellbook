# SwiftSpellbook
SwiftSpellbook is collection of additions to Swift standard library that makes development easier.

<p>
  <img src="https://img.shields.io/badge/swift-5.9-orange" />
  <img src="https://img.shields.io/badge/platforms-macOS 10.15 | iOS 13 | watchOS 6 | tvOS 13-freshgreen" />
  <img src="https://img.shields.io/badge/Xcode-15-blue" />
  <img src="https://github.com/Alkenso/SwiftSpellbook/actions/workflows/main.yml/badge.svg" />
</p>

If you've found this or other my libraries helpful, please buy me some pizza

<a href="https://www.buymeacoffee.com/alkenso"><img src="https://img.buymeacoffee.com/button-api/?text=Buy me a pizza&emoji=🍕&slug=alkenso&button_colour=FFDD00&font_colour=000000&font_family=Cookie&outline_colour=000000&coffee_colour=ffffff" /></a>

## Motivation
While participating in many projects (macOS and iOS) I use the same tools and standard types extensions.
Once I've decided stop to copy-paste code from project to project and make single library that covers lots of developer needs in utility code.

## Content
At top level, the code is organized into libraries that cover big areas.
Now there are only two:
- SpellbookFoundation: utility code
- SpellbookBinaryParsing: convenient way to read and write binary data byte-by-byte
- SpellbookHTTP: HTTP client
- SpellbookTestUtils: utility code frequently used for Unit-Tests

## SpellbookFoundation
The most of utility code lives here.
- Combine: Combine.framework extensions
- Common: Mix of commonly used entities
- DictionaryParsing: deal with data nested deeply in dictionaries
- Filesystem & Bundle: FileManager, Bundle and same utilities
- GUI: CoreGraphics utilities. This is NOT an AppKit/UIKit/SwiftUI
- Low Level: extensions to deal with (popular) C structures, unsafe types, etc. 
- ObjC Bridging: Caching Objective-C and C++ exceptions from Swift code
- System & Hardware: UNIX and Process utilities
- Threading & Concurrency: utilities that make multithead development easier
- Types & PropertyWrappers: misc types and property wrappers
- ValueObserving: utilities that allows observe and modify-with-observe on any types

# Other
If you've found this or other my libraries helpful, you could buy me some pizza

<a href="https://www.buymeacoffee.com/alkenso"><img src="https://img.buymeacoffee.com/button-api/?text=Buy me a pizza&emoji=🍕&slug=alkenso&button_colour=FFDD00&font_colour=000000&font_family=Cookie&outline_colour=000000&coffee_colour=ffffff" /></a>

You can also find Swift libraries for macOS / *OS development
- [sXPC](https://github.com/Alkenso/sXPC): type-safe wrapper around NSXPCConnection and proxy object
- [sLaunchctl](https://github.com/Alkenso/sLaunchctl): register and manage daemons and user-agents
- [sMock](https://github.com/Alkenso/sMock): Swift unit-test mocking framework similar to gtest/gmock
- [sEndpointSecurity](https://github.com/Alkenso/sEndpointSecurity.git) Swift wrapper around EndpointSecurity.framework 
- [SwiftSpellbook_macOS](https://github.com/Alkenso/SwiftSpellbook_macOS) macOS-related collection of additions to Swift standard library that makes development easier.
