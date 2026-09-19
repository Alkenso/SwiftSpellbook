# SwiftSpellbook

SwiftSpellbook is a collection of small Swift libraries for Apple platform development. It grew out of utilities reused across macOS and iOS projects. Pick the products you need; the package has no external dependencies.

<p>
  <img src="https://img.shields.io/badge/swift-6.4-orange" />
  <img src="https://img.shields.io/badge/platforms-macOS 13 | iOS 16 | watchOS 10 | tvOS 16 | visionOS 2-freshgreen" />
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

The package is split into independent products. Add only the ones you need; every product except `SpellbookCrash` builds on top of `SpellbookFoundation`.

| Product | Use it for |
| --- | --- |
| [SpellbookFoundation](#spellbookfoundation) | Everyday extensions and utilities: collections, errors, files, concurrency, observable values, logging, low-level interop |
| [SpellbookHTTP](#spellbookhttp) | Building `URLRequest`s declaratively and sending them with async/await or callbacks |
| [SpellbookBinaryParsing](#spellbookbinaryparsing) | Reading and writing binary formats byte by byte |
| [SpellbookGraphics](#spellbookgraphics) | Platform-neutral RGB colors and Core Graphics geometry/image helpers |
| [SpellbookCrash](#spellbookcrash) | Adding your own diagnostic messages to Apple crash reports |
| [SpellbookUI](#spellbookui) | Small SwiftUI conveniences |
| [SpellbookTestUtils](#spellbooktestutils) | XCTest helpers: temporary directories, test bundle access, CI-friendly timeouts |

### SpellbookFoundation

The core of the package: extensions to the standard library and Foundation, plus a set of small, focused types that remove boilerplate you would otherwise copy between projects.

#### Collections, standard types and utilities
- **Collections:** `subscript(safe:)`, `removingDuplicates()`, `sorted(by: \.keyPath)`, `min/max(by: \.keyPath)`, `firstMapped`/`lastMapped`, `keyedMap`, `recursiveMap`, `rotated`, `appending`, `Dictionary[key, create:]` and more.
- **Standard types:** `Data` ⇄ hex string and POD conversion, `Optional.get()` that throws a meaningful error instead of force-unwrapping, `Optional[default:]`, `Result.success`/`.failure`, `URL(staticString:)`, `String` path helpers, key-value string parsing, `TimeInterval.minutes(_:)`/`.hours(_:)`, `Date.inPast`/`inFuture`, `UUID.zero`.
- **Comparable:** `clamped(to:)`, the `@Clamped` property wrapper and `RawComparable` for enums with comparable raw values.
- **Diffing:** `CollectionDiff` and `DictionaryDiff` describe added, removed and changed elements between two snapshots.
- **Helpers:** `updateValue(_:using:)` for inline mutation of value types, `throwingCast`, `WildcardExpression` for glob-like (`*`, `?`) string matching, `Benchmark.measure` for quick timing, `SBUnitTime`/`SBUnitInformationStorage` units.
- **Environment:** `BuildEnvironment.isDebug`, `RunEnvironment.isXCTesting`, `isRunFromXcode`, `isXcodePreview`, `isSimulator`.
- **Protocols:** `EmptyInitializable` (types with a natural "empty" value) and `SelfIdentifiable` (`Hashable` types that serve as their own `id`).

#### Codable and dictionary parsing
- `ObjectEncoder` / `ObjectDecoder`: a uniform way to pass around "how to encode/decode" — JSON, property list, `JSONSerialization` or a custom format.
- `DictionaryCoder` converts `Codable` values to and from `[String: Any]`.
- Property wrappers `@JSONSerializable`, `@PropertyListSerializable`, `@KeyedArchiveSerializable` embed non-`Codable` values into `Codable` types.
- `DictionaryReader` / `DictionaryWriter` read and write deeply nested `[String: Any]` values (plists, JSON objects) by coding path or dot path — e.g. `dict[dotPath: "settings.network.timeout", as: Int.self]` — with descriptive `DictionaryCodingError`s.

#### Errors
- `CommonError`: a ready-to-use error with codes such as `.invalidArgument`, `.notFound`, `.unexpected`, bridging cleanly to `NSError`.
- `NSError` helpers for POSIX, `OSStatus` and Mach codes, including throwing wrappers around C calls that pick up `errno` or the returned status automatically: `try NSError.posix.try(unlink(path) == 0)`, `try NSError.osstatus.try { SecItemDelete(query) }`.
- `CustomErrorUpdating` to attach extra context (`userInfo`, related object, name) to any error, and `Error.secureCodingCompliant()` for sending errors over XPC.
- `catchingAny` turns Objective-C `NSException`s and C++ exceptions into Swift errors.
- `IOKitError` wraps `IOReturn` codes (macOS only).

#### Filesystem and Bundle
- `FileManager` extensions: `fileExists(at:)`, `directoryExists(at:)`, `removeItemIfExists`, `createDirectoryTree`, recursive attribute setting, `stat`, extended attributes (`xattr`, `setXattr`, `listXattr`, `removeXattr`), unique file names.
- `FileEnumerator`: a lazy `Sequence` of URLs over multiple locations with type filtering and per-directory skip/descend control.
- `FileStore`: read and write values to files through a pluggable store — the standard disk store, an in-memory store for tests, `Codable` coding, or a queue-synchronized variant.
- `TemporaryDirectory`: create, set up and clean up scratch directories.
- `Bundle` extensions: `name`, `shortVersion`, `version`, `existingURL(forResource:withExtension:)`.

#### Threading and concurrency
- Locks: `UnfairLock` (`os_unfair_lock`) and `RWLock` (`pthread_rwlock`), plus `NSLocking` helpers.
- `Synchronized<Value>`: a value protected by a lock or dispatch queue of your choice, with `read`/`write` closures and arithmetic shortcuts.
- `Atomic<Value>` and `AtomicFlag` for simple thread-safe values and one-time flags.
- `AsyncPromise` / `AsyncFuture`: set a value once, await it from many places.
- `AsyncSerialDispatchQueue` runs async operations strictly one after another.
- `BlockingQueue`: a producer-consumer queue with blocking `dequeue` and cancellation.
- `ConcurrentBlockOperation`: an `Operation` that finishes when your async work calls completion.
- Bridging sync and async code: `synchronouslyWithTask`, `synchronouslyWithCallback`, `DispatchQueue.syncOnMain`.
- `DispatchQueue` helpers: `debounce`, `asyncAfter(delay:)`, `asyncPeriodically`.
- `Task.sleep(forTimeInterval:)`, `UncheckedSendable`, `synchronized(_:_:)` (Objective-C `@synchronized` equivalent).

#### Value observing
A lightweight, `Sendable`-first alternative to Combine / KVO for sharing state between components:
- `ValueStore<Value>`: holds a mutable value and notifies observers about every change (`ValueChange` with `old`, `new` and optional `context`). Stores can be scoped to a sub-property (`scope(\.settings)`) so each component only sees what it needs.
- `ValueObservable<Value>`: a read-only, observable projection of a store.
- `ValueView<Value>`: a read-only accessor without observation.
- `ValueBroadcast<Value>`: fire-and-forget event notifications.
- `ValueAsk<Request, Response>`: ask all attached responders and collect their answers.
- `ValueObserver` configures delivery — `sync`, `async`, on a specific queue, with `map`/`filter`/`compactMap`. Any source can also be consumed as an `AsyncStream`.
- Property wrappers `@ValueStored`, `@ValueObserved`, `@ValueViewed`, and `ObservableObject` adapters for SwiftUI.

```swift
let store = ValueStore(initialValue: Settings())
let subscription = store.observe(.sync { change in
    print("Changed from \(change.old) to \(change.new)")
})
store.update(\.isEnabled, true)

for await change in store.scope(\.isEnabled).stream() { ... }
```

#### Types and property wrappers
- `Resource<T>`: RAII-style ownership — runs a cleanup closure on deinit (e.g. free a pointer, delete a temporary file); `DeinitAction` for arbitrary "run on deinit" logic.
- `Refreshable<Value>`: a property wrapper that recomputes its value when expired (e.g. by TTL).
- `Box`, `Weak`, `Unowned`, `Indirect`: reference, weak and indirect wrappers usable as values and in collections.
- `Closure` / `ThrowingClosure`: store and compose callbacks (one-shot, dispatched on a queue).
- Small general types: `Either`, `Pair`, `KeyValue`, `Change`, `ProgressValue`, `EmptyCodable`.

#### Logging
- `SpellbookLogger` with levels (`verbose` … `fatal`), subsystem/category sources and pluggable destinations (`print`, `NSLog`, or your own closure). The package logs its own internal issues through it, so you can route them into your logging system.

#### Combine
- `Cancellation` — a `Sendable` cancellable that is cancelled on deinit — and helpers to store it.
- `ProxyPublisher`, `ProxySubscriber`, `ProxySubscription` for building custom publishers; `Publisher.mapToChange`, `Cancellable.capturing(_:)`.

#### Low level and system
- `unsafe` pointer helpers and the `CPointer` protocol for C interop; `SafePOD`/`UnsafePOD` add `Codable`/`Hashable` to C structs (`stat`, `timespec`, `audit_token_t`, …).
- `BridgedCEnum` for Swift-friendly wrappers around C enums.
- Mach time conversions: `TimeInterval(machTime:)`, `Date(machTime:)`.
- `audit_token_t` accessors (pid, euid, …) and `NSXPCConnection.auditToken` (macOS only).
- `DeviceInfo`: hardware UUID and serial number on macOS, model name on iOS``.

### SpellbookHTTP

A thin, testable layer over `URLSession`.

- `HTTPRequest` describes a request declaratively: URL, `HTTPMethod`, query items, headers, and a body built from `Encodable` values, JSON/plist objects or raw data. It converts to `URLRequest` when sent.
- `HTTPParameters`, `HTTPHeader`, `HTTPQueryItem`, `HTTPAuthorizationType` (`.basic`, `.bearer`) are typed building blocks for headers and query strings.
- `HTTPClient` sends requests with async/await or completion handlers and returns raw `Data` or decoded objects via `ObjectDecoder`. It can carry default headers for every request. `HTTPClientProtocol` makes it easy to mock in tests.
- `HTTPResult<T>` keeps the decoded value together with its `HTTPURLResponse`, so status codes and headers stay available.

```swift
var request = HTTPRequest(urlString: "https://api.example.com/items", method: .get)
request.query.set("10", forKey: "limit")
request.headers.setAuthorization(.bearer, token)

let result = try await HTTPClient().object(for: request, decoder: .json([Item].self))
print(result.response.statusCode, result.value)
```

### SpellbookBinaryParsing

Read and write binary file formats and protocols (headers, Mach-O, custom wire formats) without manual pointer arithmetic.

- `BinaryReader` reads integers of any width, fixed-size (POD) values and raw byte ranges — either sequentially with `read`/`skip`/`seek`, or at explicit offsets with `peek` without moving the cursor. It reads from `Data` or any custom `BinaryReaderInput` (e.g. a file handle).
- `BinaryWriter` writes values sequentially or at offsets into any `BinaryWriterOutput`; `DataBinaryWriterOutput` collects the output into `Data`.
- `BinaryParsingError` reports out-of-bounds reads and other malformed input instead of crashing.

### SpellbookGraphics

Color and Core Graphics helpers that are independent of any UI framework.

- `RGBColor`: a `Codable`, `Hashable` RGBA color. Create it from hex strings (`"#FF8800"`), `CGColor`, `NSColor` or `UIColor`, and convert back to any of them or to a SwiftUI `Color`. Includes `random()`, `gray(_:)` and opacity emulation.
- Geometry: arithmetic on `CGPoint` and `CGSize`, scaling, `area`, `aspectRatio`, `CGRect.center`, centering one rect within another, vertical flipping between coordinate systems.
- `CGImage`: encode to and decode from PNG/JPEG/other `UTType` formats, read from and write to files.

### SpellbookCrash

Make crash reports explain themselves. Messages you attach appear in the *Application Specific Signature* or *Application Specific Backtrace* block of the system crash report, so you can see what the app was doing when it crashed.

- `CrashReportAugmentation.addMessage` / `removeMessage` attach and detach messages, targeting the report's signature or backtrace block.
- `CrashReportAugmentation.withMessage` scopes a message to a synchronous or async operation — it is present only while the work is running.
- `CrashInfo` exposes the underlying `__crash_info` section for advanced use.
- Has no dependencies, not even `SpellbookFoundation`, so it can be linked anywhere.

```swift
try CrashReportAugmentation.withMessage("Migrating database v3 → v4") {
    try migrateDatabase()
}
```

### SpellbookUI

SwiftUI conveniences.

- `View.modify { view in ... }` applies a transform conditionally (e.g. an OS-version-specific modifier) without breaking the modifier chain. Returning `nil` from the closure keeps the original view.

### SpellbookTestUtils

Helpers for XCTest suites.

- `testBundle` and `testTemporaryDirectory` on `XCTestCase` give access to test resources and an isolated scratch directory.
- `waitForExpectations(timeout:)` returns the wait error (if any) and uses a short, configurable default timeout (`XCTestCase.waitTimeout`).
- `XCTestCase.waitRate` and `TimeInterval.testSeconds(_:)` scale all timeouts at once — set the `SPELLBOOK_TEST_SLEEP_RATE_x5` (x2, x10, …) compilation flag on slow CI machines instead of editing tests.
- `TestData` provides sample URLs and file paths; `TestError` is a simple error to throw from mocks.

## Related projects

You can also find Swift libraries for macOS / *OS development
- [SwiftSpellbook_macOS](https://github.com/Alkenso/SwiftSpellbook_macOS): macOS-specific companion to SwiftSpellbook, built on top of it
  - `SpellbookMac`: Swift wrappers around POSIX and low-level macOS APIs: processes, `sysctl`, users and groups, ACLs, windows and XPC objects.
  - `SpellbookEndpointSecurity`: Swift wrapper around EndpointSecurity.framework for monitoring and authorizing system events.
  - `SpellbookEndpointSecurityXPC`: runs an EndpointSecurity client in a separate process and talks to it over XPC.
  - `SpellbookXPC`: type-safe `NSXPCConnection` wrapper that passes Swift types over XPC, plus a message-oriented transport with reconnects.
  - `SpellbookLaunchctl`: Swift API that mirrors `launchctl` to register and manage daemons and user agents.
  - `SpellbookHDIUtil`: Swift API that mirrors `hdiutil` to list attached disk images and their details.
  - `s_xar`, `s_membership`, `s_libproc`: module maps for system C libraries that have no Swift module.
- [sMock](https://github.com/Alkenso/sMock): Swift unit-test mocking framework similar to gtest/gmock
