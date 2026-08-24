// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "DNSSwitcher",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "DNSSwitcher",
            path: "Sources/DNSSwitcher",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "DNSSwitcherTests",
            dependencies: ["DNSSwitcher"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
