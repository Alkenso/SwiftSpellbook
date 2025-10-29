// swift-tools-version:6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftSpellbook",
    platforms: [.macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6)],
    products: [
        .library(
            name: "SpellbookFoundation",
            targets: ["SpellbookFoundation"]
        ),
        .library(
            name: "SpellbookHTTP",
            targets: ["SpellbookHTTP"]
        ),
        .library(
            name: "SpellbookBinaryParsing",
            targets: ["SpellbookBinaryParsing"]
        ),
        .library(
            name: "SpellbookTestUtils",
            targets: ["SpellbookTestUtils"]
        ),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "SpellbookFoundation",
            dependencies: ["_SpellbookFoundationObjC"],
            linkerSettings: [
                .linkedLibrary("bsm", .when(platforms: [.macOS])),
            ],
        ),
        .target(
            name: "_SpellbookFoundationObjC",
            path: "Sources/SpellbookFoundationObjC",
            publicHeadersPath: "."
        ),
        .target(
            name: "SpellbookHTTP",
            dependencies: ["SpellbookFoundation"]
        ),
        .target(
            name: "SpellbookBinaryParsing",
            dependencies: ["SpellbookFoundation"]
        ),
        .target(
            name: "SpellbookTestUtils",
            dependencies: ["SpellbookFoundation"]
        ),
        .testTarget(
            name: "SpellbookTests",
            dependencies: ["SpellbookFoundation", "SpellbookBinaryParsing", "SpellbookTestUtils"]
        ),
        .testTarget(
            name: "SpellbookTestUtilsTests",
            dependencies: ["SpellbookFoundation", "SpellbookTestUtils"]
        ),
    ],
    swiftLanguageModes: [.v5]
)

for target in package.targets {
    var settings = target.swiftSettings ?? []
    settings.append(contentsOf: [
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableUpcomingFeature("InferIsolatedConformances"),
        .enableUpcomingFeature("MemberImportVisibility"),
    ])
    target.swiftSettings = settings
}
