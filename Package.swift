// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
        name: "InfomaniakCore",
        platforms: [
            .iOS(.v11),
        ],
        products: [
            // Products define the executables and libraries produced by a package, and make them visible to other packages.
            .library(
                    name: "InfomaniakCore",
                    targets: ["InfomaniakCore"]),
        ],
        dependencies: [
            .package(url: "https://github.com/Alamofire/Alamofire", .upToNextMajor(from: "5.2.2")),
            .package(name: "InfomaniakLogin", url: "https://github.com/Infomaniak/ios-login.git", .upToNextMajor(from: "1.4.0")),
            .package(url: "https://github.com/immortal79/LocalizeKit", .upToNextMajor(from: "1.0.1")),
            .package(url: "https://github.com/onevcat/Kingfisher", .upToNextMajor(from: "6.3.1")),
            .package(name: "Sentry", url: "https://github.com/getsentry/sentry-cocoa", .upToNextMajor(from: "7.2.9"))
        ],
        targets: [
            .target(
                    name: "InfomaniakCore",
                    dependencies: ["Alamofire", "InfomaniakLogin", "Kingfisher", "LocalizeKit", "Sentry"]),
            .testTarget(
                    name: "InfomaniakCoreTests",
                    dependencies: ["InfomaniakCore"]),
        ]
)
