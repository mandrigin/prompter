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
    targets: [
        .executableTarget(
            name: "Prompter",
            exclude: ["Resources/Info.plist", "Resources/AppIcon.icns"]
        )
    ]
)
