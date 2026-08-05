// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "GhostMonitor",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "GhostMonitor",
            targets: ["GhostMonitor"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "GhostMonitor",
            dependencies: [],
            path: "Sources/GhostMonitor",
            swiftSettings: [
                .enableUpcomingFeature("BareSlashRegexLiterals")
            ]
        ),
        .testTarget(
            name: "GhostMonitorTests",
            dependencies: ["GhostMonitor"],
            path: "Tests/GhostMonitorTests"
        )
    ]
)
