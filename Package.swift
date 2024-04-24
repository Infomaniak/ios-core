// swift-tools-version:5.7
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
        ),
        .library(
            name: "InfomaniakCoreDB",
            targets: ["InfomaniakCoreDB"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/Infomaniak/ios-dependency-injection", .upToNextMajor(from: "2.0.0")),
        .package(url: "https://github.com/Infomaniak/ios-login", .upToNextMajor(from: "6.0.0")),
        .package(url: "https://github.com/Alamofire/Alamofire", .upToNextMajor(from: "5.8.0")),
        .package(url: "https://github.com/getsentry/sentry-cocoa", .upToNextMajor(from: "8.18.0")),
        .package(url: "https://github.com/realm/realm-swift", .upToNextMajor(from: "10.45.0")),
        .package(url: "https://github.com/CocoaLumberjack/CocoaLumberjack", .upToNextMajor(from: "3.8.0")),
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", .upToNextMajor(from: "0.9.0")),
        .package(url: "https://github.com/MarcoEidinger/OSInfo.git", .upToNextMajor(from: "1.0.0"))
    ],
    targets: [
        .target(
            name: "InfomaniakCore",
            dependencies: [
                "Alamofire",
                .product(name: "InfomaniakDI", package: "ios-dependency-injection"),
                .product(name: "InfomaniakLogin", package: "ios-login"),
                .product(name: "Sentry", package: "sentry-cocoa"),
                .product(name: "RealmSwift", package: "realm-swift"),
                .product(name: "CocoaLumberjackSwift", package: "CocoaLumberjack"),
                .product(name: "OSInfo", package: "OSInfo"),
            ]
        ),
        .target(
            name: "InfomaniakCoreDB",
            dependencies: [
                "InfomaniakCore",
                .product(name: "InfomaniakDI", package: "ios-dependency-injection"),
                .product(name: "RealmSwift", package: "realm-swift"),
            ]
        ),
        .testTarget(
            name: "InfomaniakCoreTests",
            dependencies: ["InfomaniakCore", "InfomaniakCoreDB" ,"ZIPFoundation"],
            resources: [Resource.copy("Resources/Matterhorn_as_seen_from_Zermatt,_Wallis,_Switzerland,_2012_August,Wikimedia_Commons.heic"),
                        Resource.copy("Resources/Matterhorn_as_seen_from_Zermatt,_Wallis,_Switzerland,_2012_August,Wikimedia_Commons.jpg"),
                        Resource.copy("Resources/dummy.pdf")]
        )
    ]
)
