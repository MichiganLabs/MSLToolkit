// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MSLToolKit",
    platforms: [
        .iOS(.v14),
        .macOS(.v10_14),
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "MSLCombine",
            targets: ["MSLCombine"]
        ),
        .library(
            name: "MSLCoreData",
            targets: ["MSLCoreData"]
        ),
        .library(
            name: "MSLFoundation",
            targets: ["MSLFoundation"]
        ),
        .library(
            name: "MSLNetworking",
            targets: ["MSLNetworking"]
        ),
        .library(
            name: "MSLSwiftUI",
            targets: ["MSLSwiftUI"]
        ),
        .library(
            name: "MSLUIKit",
            targets: ["MSLUIKit"]
        ),
        .library(
            name: "MSLXCTest",
            targets: ["MSLXCTest"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.8.1"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "MSLFoundation",
            dependencies: []
        ),
        .target(
            name: "MSLCombine",
            dependencies: []
        ),
        .target(
            name: "MSLNetworking",
            dependencies: [
                .product(name: "Alamofire", package: "Alamofire"),
            ]
        ),
        .target(
            name: "MSLCoreData",
            dependencies: [
                "MSLFoundation"
            ]
        ),
        .target(
            name: "MSLSwiftUI",
            dependencies: []
        ),
        .target(
            name: "MSLUIKit",
            dependencies: []
        ),
        .target(
            name: "MSLXCTest",
            dependencies: []
        ),
        .testTarget(
            name: "MSLFoundationTests",
            dependencies: ["MSLFoundation"]
        ),
    ]
)
