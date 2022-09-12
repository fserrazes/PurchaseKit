// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PurchaseKit",
    platforms: [
        .macOS(.v12),
        .watchOS(.v8),
        .tvOS(.v15),
        .iOS(.v15)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "PurchaseKit",
            targets: ["PurchaseKit"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        .target(name: "PurchaseKit", dependencies: [], path: "Sources")
    ]
)
