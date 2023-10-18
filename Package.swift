// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftSpellbook",
    platforms: [.macOS(.v10_10), .iOS(.v9), .tvOS(.v9), .watchOS(.v2)],
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
            name: "SpellbookTestUtils",
            targets: ["SpellbookTestUtils"]
        ),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "SpellbookFoundation",
            dependencies: ["SpellbookFoundationObjC"],
            linkerSettings: [
                .linkedLibrary("bsm", .when(platforms: [.macOS])),
            ]
        ),
        .target(
            name: "SpellbookFoundationObjC",
            publicHeadersPath: "."
        ),
        .target(
            name: "SpellbookHTTP",
            dependencies: ["SpellbookFoundation"]
        ),
        .target(
            name: "SpellbookTestUtils",
            dependencies: ["SpellbookFoundation"]
        ),
        .testTarget(
            name: "SpellbookTests",
            dependencies: ["SpellbookFoundation", "SpellbookTestUtils"]
        ),
        .testTarget(
            name: "SpellbookTestUtilsTests",
            dependencies: ["SpellbookFoundation", "SpellbookTestUtils"]
        ),
    ]
)
