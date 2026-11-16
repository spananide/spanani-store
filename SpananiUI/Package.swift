// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SpananiUI",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "SpananiUI",
            targets: ["SpananiUI"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "SpananiUI",
            dependencies: [],
            resources: [
                .process("Resources")
            ]
        )
    ],
    swiftLanguageVersions: [.v5]
)
