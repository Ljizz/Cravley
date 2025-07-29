// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Cravely",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "Cravely",
            targets: ["Cravely"]),
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "10.0.0"),
        .package(url: "https://github.com/RevenueCat/purchases-ios", from: "4.0.0"),
        .package(url: "https://github.com/daltoniam/Starscream", from: "4.0.0"),
        .package(url: "https://github.com/kean/Nuke", from: "12.0.0")
    ],
    targets: [
        .target(
            name: "Cravely",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseStorage", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
                .product(name: "RevenueCat", package: "purchases-ios"),
                .product(name: "Starscream", package: "Starscream"),
                .product(name: "Nuke", package: "Nuke"),
                .product(name: "NukeUI", package: "Nuke")
            ]
        ),
        .testTarget(
            name: "CravelyTests",
            dependencies: ["Cravely"]),
    ]
)