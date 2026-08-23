// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "PingIt",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "PingIt",
            path: "Sources/PingIt"
        )
    ]
)
