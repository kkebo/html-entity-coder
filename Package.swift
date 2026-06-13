// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "html-entity-coder",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .watchOS(.v26),
        .tvOS(.v26),
        .macCatalyst(.v26),
        .visionOS(.v26),
    ],
    products: [
        .library(
            name: "HTMLEntityCoder",
            targets: ["HTMLEntityCoder"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-collections", "1.3.0"..<"2.0.0")
    ],
    targets: [
        .target(
            name: "HTMLEntityCoder",
            dependencies: [
                .product(name: "DequeModule", package: "swift-collections")
            ]
        ),
        .testTarget(
            name: "HTMLEntityCoderTests",
            dependencies: [
                .target(name: "HTMLEntityCoder")
            ],
            resources: [
                .process("Resources")
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
