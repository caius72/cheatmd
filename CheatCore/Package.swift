// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "CheatCore",
    platforms: [.macOS(.v26)],
    products: [.library(name: "CheatCore", targets: ["CheatCore"])],
    targets: [
        .target(name: "CheatCore", resources: [.copy("Resources/sample.md")]),
        .testTarget(name: "CheatCoreTests", dependencies: ["CheatCore"]),
    ]
)
