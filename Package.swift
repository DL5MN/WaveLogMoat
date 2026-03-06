// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "WaveLogMoat",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "WaveLogMoat",
            targets: ["WaveLogMoat"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.5.0"),
    ],
    targets: [
        .target(
            name: "WaveLogMoat",
            dependencies: [
                .product(name: "Sparkle", package: "Sparkle"),
            ],
            exclude: [
                "Info.plist",
            ],
            swiftSettings: [
                .define("BUILDING_FOR_SWIFT_PACKAGE"),
            ]
        ),
        .testTarget(
            name: "WaveLogMoatTests",
            dependencies: ["WaveLogMoat"]
        ),
    ]
)
