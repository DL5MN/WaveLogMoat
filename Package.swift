// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "WaveLogMate",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "WaveLogMate",
            targets: ["WaveLogMate"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.5.0"),
    ],
    targets: [
        .target(
            name: "WaveLogMate",
            dependencies: [
                .product(name: "Sparkle", package: "Sparkle"),
            ],
            exclude: [
                "Info.plist",
                "Assets.xcassets",
            ],
            swiftSettings: [
                .define("BUILDING_FOR_SWIFT_PACKAGE"),
            ]
        ),
        .testTarget(
            name: "WaveLogMateTests",
            dependencies: ["WaveLogMate"]
        ),
    ]
)
