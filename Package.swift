// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ARUnderstanding",
    platforms: [
        .visionOS(.v2),
        .iOS(.v18),
        .macOS(.v15),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "ARUnderstanding",
            targets: ["ARUnderstanding"]),
    ],
    dependencies: [
        .package(url: "https://github.com/johnhaney/JSONLStream", branch: "main"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "ARUnderstanding"),
        .testTarget(
            name: "ARUnderstandingTests",
            dependencies: ["ARUnderstanding"]),
    ]
)
