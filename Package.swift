// swift-tools-version:6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftSpellbook",
    platforms: [.macOS(.v12), .iOS(.v15), .tvOS(.v15), .watchOS(.v9), .visionOS(.v1)],
    products: [
        .library(
            name: "SpellbookFoundation",
            targets: ["SpellbookFoundation", "_SpellbookFoundationObjC"]
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
            name: "SpellbookGraphics",
            targets: ["SpellbookGraphics"]
        ),
        .library(
            name: "SpellbookCrash",
            targets: ["SpellbookCrash"]
        ),
        .library(
            name: "SpellbookUI",
            targets: ["SpellbookUI"]
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
            swiftSettings: [
                .enableExperimentalFeature("CheckImplementationOnly")
            ],
            linkerSettings: [
                .linkedLibrary("bsm", .when(platforms: [.macOS])),
            ]
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
            name: "SpellbookGraphics",
            dependencies: ["SpellbookFoundation"],
            linkerSettings: [
                .linkedFramework("CoreGraphics"),
            ]
        ),
        .target(
            name: "SpellbookCrash",
            swiftSettings: [
                .enableExperimentalFeature("SymbolLinkageMarkers")
            ]
        ),
        .target(
            name: "SpellbookUI",
            dependencies: ["SpellbookFoundation"],
            linkerSettings: [
                .linkedFramework("SwiftUI"),
            ]
        ),
        .target(
            name: "SpellbookTestUtils",
            dependencies: ["SpellbookFoundation"]
        ),
        .testTarget(
            name: "SpellbookTests",
            dependencies: ["SpellbookFoundation", "SpellbookBinaryParsing", "SpellbookGraphics", "SpellbookCrash", "SpellbookTestUtils"]
        ),
        .testTarget(
            name: "SpellbookTestUtilsTests",
            dependencies: ["SpellbookFoundation", "SpellbookTestUtils"]
        ),
    ],
    swiftLanguageModes: [.v5, .v6]
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
