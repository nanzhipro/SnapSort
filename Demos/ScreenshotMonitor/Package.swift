// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "ScreenshotMonitor",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "ScreenshotMonitor",
            targets: ["ScreenshotMonitor"]
        ),
        .executable(
            name: "ScreenshotMonitorCLI",
            targets: ["ScreenshotMonitorCLI"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0")
    ],
    targets: [
        .target(
            name: "ScreenshotMonitor",
            dependencies: []
        ),
        .executableTarget(
            name: "ScreenshotMonitorCLI",
            dependencies: [
                "ScreenshotMonitor",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(
            name: "ScreenshotMonitorTests",
            dependencies: ["ScreenshotMonitor"]
        ),
    ]
)
