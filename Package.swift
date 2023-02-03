// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "InfomaniakCore",
    platforms: [
        .iOS(.v12),
        .macOS(.v11)
    ],
    products: [
        .library(
            name: "InfomaniakCore",
            targets: ["InfomaniakCore"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/Infomaniak/ios-dependency-injection", .upToNextMajor(from: "1.1.10")),
        .package(url: "https://github.com/Alamofire/Alamofire", .upToNextMajor(from: "5.2.2")),
        .package(url: "https://github.com/getsentry/sentry-cocoa", .upToNextMajor(from: "7.2.9")),
        .package(url: "https://github.com/realm/realm-swift", .upToNextMajor(from: "10.0.0")),
        .package(url: "https://github.com/CocoaLumberjack/CocoaLumberjack.git", .upToNextMajor(from: "3.7.0")),
    ],
    targets: [
        .target(
            name: "InfomaniakCore",
            dependencies: [
                "Alamofire",
                .product(name: "InfomaniakDI", package: "ios-dependency-injection"),
                .product(name: "Sentry", package: "sentry-cocoa"),
                .product(name: "RealmSwift", package: "realm-swift"),
                .product(name: "CocoaLumberjackSwift", package: "CocoaLumberjack"),
            ]
        ),
        .testTarget(
            name: "InfomaniakCoreTests",
            dependencies: ["InfomaniakCore"]
        )
    ]
)
