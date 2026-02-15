// swift-tools-version:5.11

import PackageDescription

let package = Package(
    name: "BetterSwiftAX",
    platforms: [.macOS(.v10_15)],
    products: [
        .library(
            name: "BetterSwiftAX",
            targets: ["AccessibilityControl"]
        )
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
        .executableTarget(
            name: "AXConstantsGenerator",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .plugin(
            name: "GenerateAXConstants",
            capability: .command(
                intent: .custom(
                    verb: "generate-ax-constants",
                    description: "Regenerate AX constant Swift files from HIServices headers"
                ),
                permissions: [
                    .writeToPackageDirectory(reason: "Writes generated Swift source files into Sources/AccessibilityControl")
                ]
            ),
            dependencies: ["AXConstantsGenerator"]
        )
    ]
)
