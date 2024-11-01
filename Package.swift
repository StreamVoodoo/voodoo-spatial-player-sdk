// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "VoodooSpatialPlayer",
    platforms: [.visionOS(.v1)],
    products: [
        .library(
            name: "VoodooSpatialPlayer",
            targets: ["VoodooSpatialPlayer"]),
    ],
    targets: [
        .target(
            name: "VoodooSpatialPlayer"),
    ]
)
