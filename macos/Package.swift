// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Prompter",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Prompter", targets: ["Prompter"])
    ],
    dependencies: [
        .package(url: "https://github.com/gonzalezreal/swift-markdown-ui", from: "2.3.0")
    ],
    targets: [
        .executableTarget(
            name: "Prompter",
            dependencies: [
                .product(name: "MarkdownUI", package: "swift-markdown-ui")
            ],
            exclude: ["Resources/Info.plist", "Resources/AppIcon.icns"]
        )
    ]
)
