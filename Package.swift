// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "AppLauncher",
    platforms: [.macOS(.v12)],
    targets: [
        .executableTarget(
            name: "AppLauncher",
            path: "Sources/AppLauncher"
        )
    ]
)
