// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Nani",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.5.0")
    ],
    targets: [
        .executableTarget(
            name: "Nani",
            dependencies: [
                .product(name: "Sparkle", package: "Sparkle")
            ],
            path: "Nani",
            exclude: [
                "Resources/Sounds/OpenCode Desktop.dmg"
            ],
            resources: [
                .process("Resources")
            ]
        )
    ]
)
