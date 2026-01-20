// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "BetterSwiftAX",
    platforms: [.macOS(.v10_15)],
    products: [
        .library(
            name: "BetterSwiftAX",
            targets: ["AccessibilityControl"]
        ),
        .executable(
            name: "axdump",
            targets: ["axdump"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
    ],
    targets: [
        .target(
            name: "CWindowControl"
        ),
        .target(
            name: "WindowControl",
            dependencies: ["CWindowControl"]
        ),
        .target(
            name: "CAccessibilityControl"
        ),
        .target(
            name: "AccessibilityControl",
            dependencies: ["CAccessibilityControl", "WindowControl"]
        ),
        .target(
            name: "axdump",
            dependencies: [
                "AccessibilityControl",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
    ]
)
