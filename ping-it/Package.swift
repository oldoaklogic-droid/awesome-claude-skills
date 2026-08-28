// swift-tools-version: 5.9

// PING IT — iOS app package.
// Open this file in Xcode, pick an iPhone simulator, press Run.
import PackageDescription
import AppleProductTypes

let package = Package(
    name: "PingIt",
    platforms: [
        .iOS("17.0")
    ],
    products: [
        .iOSApplication(
            name: "PING IT",
            targets: ["PingIt"],
            bundleIdentifier: "app.pingit.demo",
            teamIdentifier: "",
            displayVersion: "1.0",
            bundleVersion: "1",
            supportedDeviceFamilies: [
                .phone,
                .pad
            ],
            supportedInterfaceOrientations: [
                .portrait,
                .landscapeRight,
                .landscapeLeft
            ]
        )
    ],
    targets: [
        .executableTarget(
            name: "PingIt",
            path: "Sources/PingIt"
        )
    ]
)
