// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "sMHT",
    platforms: [.macOS(.v10_10), .iOS(.v8), .tvOS(.v9), .watchOS(.v2)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "sMHT",
            targets: ["sMHT"]),
        .library(
            name: "sMHTTestUtils",
            targets: ["sMHT"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "sMHT",
            dependencies: []),
        .target(
            name: "sMHTTestUtils",
            dependencies: []),
        .testTarget(
            name: "sMHTTests",
            dependencies: ["sMHT", "sMHTTestUtils"],
            linkerSettings: [LinkerSetting.linkedLibrary("bsm", .when(platforms: [.macOS]))]),
        .testTarget(
            name: "sMHTTestUtilsTests",
            dependencies: ["sMHT", "sMHTTestUtils"]),
    ]
)
