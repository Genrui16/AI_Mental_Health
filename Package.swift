// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MoodTrackerAppPackage",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "MoodTrackerApp", targets: ["MoodTrackerApp"])
    ],
    targets: [
        .executableTarget(
            name: "MoodTrackerApp",
            path: "MoodTrackerApp"
        )
    ]
)
