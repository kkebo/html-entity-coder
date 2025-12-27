// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "HTMLEntityCoder",
    products: [
        .library(
            name: "HTMLEntityCoder",
            targets: ["HTMLEntityCoder"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-collections", from: "1.3.0")
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
