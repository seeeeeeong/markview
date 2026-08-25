// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MdLens",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "MdLens",
            path: "Sources/MdLens"
        )
    ]
)
