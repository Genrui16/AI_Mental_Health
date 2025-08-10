// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MoodTrackerAppPackage",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .iOSApplication(
            name: "MoodTrackerApp",
            targets: ["MoodTrackerApp"],
            bundleIdentifier: "com.example.MoodTrackerApp",
            teamIdentifier: "ABCDE12345",
            displayVersion: "1.0",
            bundleVersion: "1",
            infoPlist: .file("MoodTrackerApp/Info.plist"),
            appCategory: .healthcareAndFitness
        )
    ],
    targets: [
        .executableTarget(
            name: "MoodTrackerApp",
            path: "MoodTrackerApp"
        )
    ]
)
