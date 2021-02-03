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
            .package(url: "https://github.com/Alamofire/Alamofire", from: "5.2.2"),
            .package(name: "InfomaniakLogin", url: "git@github.com:Infomaniak/ios-login.git", from: "1.3.0"),
            .package(url: "https://github.com/immortal79/LocalizeKit", from: "1.0.1")
        ],
        targets: [
            .target(
                    name: "InfomaniakCore",
                    dependencies: ["Alamofire", "InfomaniakLogin", "LocalizeKit"]),
            .testTarget(
                    name: "InfomaniakCoreTests",
                    dependencies: ["InfomaniakCore"]),
        ]
)
