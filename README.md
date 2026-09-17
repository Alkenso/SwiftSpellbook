# SwiftSpellbook

SwiftSpellbook is a collection of small Swift libraries for Apple platform development. It grew out of utilities reused across macOS and iOS projects. Pick the products you need; the package has no external dependencies.

<p>
  <img src="https://img.shields.io/badge/swift-6.4-orange" />
  <img src="https://img.shields.io/badge/platforms-macOS 12 | iOS 15 | watchOS 9 | tvOS 15-freshgreen" />
  <img src="https://img.shields.io/badge/Xcode-26 | 27-blue" />
  <img src="https://github.com/Alkenso/SwiftSpellbook/actions/workflows/main.yml/badge.svg" />
</p>

If you've found this or other my libraries helpful, share some beer with me :D
<br>
[![Buy Me a Beer 🍺](https://img.shields.io/badge/Buy%20Me%20a%20Beer-ffdd00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black)](https://www.buymeacoffee.com/alkenso)


## Motivation
While participating in many projects (macOS and iOS) I use the same tools and standard types extensions.
Once I've decided stop to copy-paste code from project to project and make single library that covers lots of developer needs in utility code.


## Libraries

### SpellbookFoundation

General purpose utilities used throughout the package. The main areas are:

- **Common and Errors:** collection and `Codable` extensions, logging, cancellation, wildcard matching, `CommonError`, and error helpers.
- **DictionaryParsing and Filesystem & Bundle:** nested dictionary reading and writing, `FileStore`, `FileEnumerator`, and `TemporaryDirectory`.
- **Threading & Concurrency:** locks, `Synchronized`, `Atomic`, queues, promises, and synchronous/asynchronous bridges.
- **ValueObserving:** stores, broadcasts, observers, and views for sharing and tracking values.
- **Types & PropertyWrappers:** `Either`, `Pair`, boxing, refreshable values, and resource lifetime helpers.
- **Combine, Low Level, and System & Hardware:** publisher helpers, memory and C interop, process information, and device information. Some APIs, such as `IOKitError`, are macOS only.

### SpellbookHTTP

Build and send HTTP requests with `URLSession`.

- `HTTPRequest` builds requests; `HTTPMethod`, `HTTPHeader`, and `HTTPQueryItem` describe their parts.
- `HTTPClient` offers callback and async APIs for data or decoded objects; `HTTPResult` keeps the value and HTTP response together.

### SpellbookBinaryParsing

Read and write binary data at explicit offsets or sequentially.

- `BinaryReader` reads bytes and fixed-size values from `Data` or a custom `BinaryReaderInput`.
- `BinaryWriter` writes to a `BinaryWriterOutput`, including the provided `DataBinaryWriterOutput`; `BinaryParsingError` reports parsing failures.

### SpellbookGraphics

Color and Core Graphics conveniences, separate from UI views.

- `RGBColor` represents RGBA values, accepts hex colors, and bridges to `CGColor` and available platform color types.
- Core Graphics extensions add geometry operations and `CGImage` file conversion helpers.

### SpellbookCrash

Attach application context to Apple crash reports.

- `CrashReportAugmentation` adds and removes messages, including scoped messages for synchronous or async work.
- `CrashInfo` provides access to the crash report's `__crash_info` storage.

### SpellbookUI

A small SwiftUI extension for conditionally transforming a view.

- `View.modify` applies a transform when it produces a view and otherwise returns the original view.

### SpellbookTestUtils

Helpers for XCTest suites.

- `XCTestCase` and `TimeInterval` extensions provide test bundles, temporary directories, and scaled expectation timeouts.
- `TestData` supplies sample URLs, while `TestError` provides a simple error for tests.

## Related projects
If you've found this or other my libraries helpful, you could buy me some pizza

<a href="https://www.buymeacoffee.com/alkenso"><img src="https://img.buymeacoffee.com/button-api/?text=Buy me a pizza&emoji=🍕&slug=alkenso&button_colour=FFDD00&font_colour=000000&font_family=Cookie&outline_colour=000000&coffee_colour=ffffff" /></a>

You can also find Swift libraries for macOS / *OS development
- [sXPC](https://github.com/Alkenso/sXPC): type-safe wrapper around NSXPCConnection and proxy object
- [sLaunchctl](https://github.com/Alkenso/sLaunchctl): register and manage daemons and user-agents
- [sMock](https://github.com/Alkenso/sMock): Swift unit-test mocking framework similar to gtest/gmock
- [sEndpointSecurity](https://github.com/Alkenso/sEndpointSecurity.git) Swift wrapper around EndpointSecurity.framework 
- [SwiftSpellbook_macOS](https://github.com/Alkenso/SwiftSpellbook_macOS) macOS-related collection of additions to Swift standard library that makes development easier.
