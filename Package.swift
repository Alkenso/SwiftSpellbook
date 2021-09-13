// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftConvenience",
    platforms: [.macOS(.v10_10), .iOS(.v9), .tvOS(.v9), .watchOS(.v2)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "SwiftConvenience",
            targets: ["SwiftConvenience", "SwiftConvenienceObjcBridge"]
        ),
        .library(
            name: "SwiftConvenienceTestUtils",
            targets: ["SwiftConvenienceTestUtils"]
        ),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "SwiftConvenience",
            dependencies: ["SwiftConvenienceObjcBridge"]
        ),
        .target(
            name: "SwiftConvenienceObjcBridge",
            dependencies: [],
            publicHeadersPath: "."
        ),
        .target(
            name: "SwiftConvenienceTestUtils",
            dependencies: ["SwiftConvenience"]
        ),
        .testTarget(
            name: "SwiftConvenienceTests",
            dependencies: ["SwiftConvenience", "SwiftConvenienceTestUtils"],
            linkerSettings: [LinkerSetting.linkedLibrary("bsm", .when(platforms: [.macOS]))]
        ),
        .testTarget(
            name: "SwiftConvenienceTestUtilsTests",
            dependencies: ["SwiftConvenience", "SwiftConvenienceTestUtils"],
            linkerSettings: [LinkerSetting.linkedLibrary("bsm", .when(platforms: [.macOS]))]
        ),
    ]
)
