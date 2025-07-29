// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "Cravely",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "Cravely",
            targets: ["Cravely"]
        ),
    ],
    dependencies: [
        // Add external dependencies here if needed
    ],
    targets: [
        .target(
            name: "Cravely",
            dependencies: [],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "CravelyTests",
            dependencies: ["Cravely"]
        ),
    ]
)