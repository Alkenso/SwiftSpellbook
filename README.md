# SwiftSpellbook
SwiftSpellbook is collection of additions to Swift standard library that makes development easier.

## Motivation
While participating in many projects (macOS and iOS) I use the same tools and standard types extensions.
Once I've decided stop to copy-paste code from project to project and make single library that covers lots of developer needs in utility code.

## Content
At top level, the code is organized into libraries that cover big areas.
Now there are only two:
- SpellbookFoundation: utility code
- SpellbookHTTP: HTTP client
- SpellbookTestUtils: utility code frequently used for Unit-Tests

The libraries/targets are organized as one level nested folders to distinguish between areas they are related to.

## SpellbookFoundation
The most of utility code lives here.
- BinaryParsing: read and write data buffers or files in raw binary format
- Combine: Combine.framework extensions
- Common: 
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
If you've found this or other my libraries helpful, you could [buy me some pizza](https://www.buymeacoffee.com/alkenso).

You can also find Swift libraries for macOS / *OS development
- [sXPC](https://github.com/Alkenso/sXPC): type-safe wrapper around NSXPCConnection and proxy object
- [sLaunchctl](https://github.com/Alkenso/sLaunchctl): register and manage daemons and user-agents
- [sMock](https://github.com/Alkenso/sMock): Swift unit-test mocking framework similar to gtest/gmock
- [sEndpointSecurity](https://github.com/Alkenso/sEndpointSecurity.git) Swift wrapper around EndpointSecurity.framework 
