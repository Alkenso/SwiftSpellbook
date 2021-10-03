# SwiftConvenience
Convenient additions to Swift standard library that makes development pleasant.

### Brief history
While participating in many projects (mostly macOS) I use the same tools and standard types extensions.
Once I've decided stop to copy-paste code from project to project and make single library that covers lots of developer needs in utility code.

### Content
#### Common
- CancellationToken: track cancelled state of the tasks
- CommonError: most common error types in developers' practice
- Environment: runtime access to build environment: if debug, if testing, etc.
- Some standard types extensions
- Some utility types
#### Filesystem & Bundle
- Bundle: convenience extensions
- FileManager: recursive setAttributes and the same
- FileEnumerator: Swift approach for deep enumeration of the filesystem
- Temporary Directory: simple working with temporary files and directories
#### Low level
- IOKitError: swift error wrapping IOKit statuses
- Mach: mach utilities
- POD: conformance popular C structs to Swift Equatable / Codable / etc 
- Unsafe: a bit more UnsafePointer... utilities
#### System & Hardware
- DeviceInfo: platform-dependent information about device (model, serial, etc)
- Process: convenience extensions
#### Wrappers & PropertyWrappers
- Atomic
- Box / Weak / WeakBox
- Clamping: restrict value type to some bounds
- Synchronized: object wrapper around value to provide thread-safety
- Resource (RAII wrapper, smart pointer analog)
#### BinaryParsing
- Utilities to serialize / deserialize things in binary format
#### Misc
- WildcardExpression: same as RegularExpression, but for wildcards (?, *)
- Transfromer: generic approach of transforming one value to another using multiple 'reducers'
#### Objective-C
- NSXPCConnection: audit_token_t property
- NSException: catching Obj-C exceptions from Swift code
#### Testing
- convenient utilities used in XCTests

### Other
You can also find Swift libraries for macOS / *OS development
- [sXPC](https://github.com/Alkenso/sXPC): type-safe wrapper around NSXPCConnection and proxy object
- [sLaunchctl](https://github.com/Alkenso/sLaunchctl): register and manage daemons and user-agents
- [sMock](https://github.com/Alkenso/sMock): Swift unit-test mocking framework similar to gtest/gmock
