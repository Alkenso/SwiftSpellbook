# SwiftConvenience
Convenient additions to Swift standard library that makes development pleasant.

### Brief history
While participating in many projects (mostly macOS) I use the same tools and standard types extensions.
Once I've decided stop to copy-paste code from project to project and make single library that covers lots of developer needs in utility code.

### Content
#### Extensions
- Bundle
- FileManager
- Process
- Standard Types (URL, Data, UUID, Result, ...)
#### Low level
- audit_token_t
- POSIX stat
#### Utility types
- CommonError
- ValueView
- KeyValue struct
- DeinitAction
#### Filesystem
- FileEnumerator (Swift approach for deep enumeration of the file system) 
#### Multithreading
- Synchronized (thread-safe wrapper around T)
- Atomic (property wrapper to safely read/assign values from different threads)
#### Working with String
- WildcardExpression


### Other
You can also find Swift libraries for macOS / *OS development
- sXPC: type-safe wrapper around NSXPCConnection and proxy object
- sLaunchctl: register and manage daemons and user-agents
- sMock: Swift unit-test mocking framework similar to gtest/gmock
