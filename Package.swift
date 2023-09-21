// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftConvenience",
    platforms: [.macOS(.v10_10), .iOS(.v9), .tvOS(.v9), .watchOS(.v2)],
    products: [
        .library(
            name: "SwiftConvenience",
            targets: ["SwiftConvenience"]
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
            dependencies: ["SwiftConvenienceObjC"],
            linkerSettings: [
                .linkedLibrary("bsm", .when(platforms: [.macOS])),
            ]
        ),
        .target(
            name: "SwiftConvenienceObjC",
            publicHeadersPath: "."
        ),
        .target(
            name: "SwiftConvenienceTestUtils",
            dependencies: ["SwiftConvenience"]
        ),
        .testTarget(
            name: "SwiftConvenienceTests",
            dependencies: ["SwiftConvenience", "SwiftConvenienceTestUtils"]
        ),
        .testTarget(
            name: "SwiftConvenienceTestUtilsTests",
            dependencies: ["SwiftConvenience", "SwiftConvenienceTestUtils"]
        ),
    ]
)
