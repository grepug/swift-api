// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-api",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SwiftAPI",
            targets: [
                "SwiftAPICore",
                "ContextEndpoints",
            ]),
        .library(
            name: "SwiftAPIClient",
            targets: [
                "SwiftAPICore",
                "SwiftAPIClient",
                "ContextEndpoints",
            ]),
        .library(
            name: "SwiftAPICore",
            targets: [
                "SwiftAPICore"
            ]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "SwiftAPICore",
            dependencies: [],
            path: "Sources/Core"
        ),
        .target(
            name: "SwiftAPIClient",
            dependencies: [
                "SwiftAPICore"
            ],
            path: "Sources/Client"
        ),
        .target(
            name: "ContextEndpoints",
            dependencies: [
                "SwiftAPICore"
            ],
            path: "Sources/Endpoints"
        ),
        .testTarget(
            name: "SwiftAPITests",
            dependencies: [
                "SwiftAPICore",
                "SwiftAPIClient",
                "ContextEndpoints",
            ]
        ),
    ]
)
