// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LufthansaDLRPrep",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "LufthansaDLRPrep", targets: ["LufthansaDLRPrep"])
    ],
    targets: [
        .executableTarget(name: "LufthansaDLRPrep")
    ]
)
