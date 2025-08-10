// swift-tools-version: 5.9
import PackageDescription

#if os(macOS)
let products: [Product] = [
    .iOSApplication(
        name: "MoodTrackerApp",
        targets: ["MoodTrackerApp"],
        bundleIdentifier: "com.example.MoodTrackerApp",
        teamIdentifier: "ABCDE12345",
        displayVersion: "1.0",
        bundleVersion: "1",
        infoPlist: .file(path: "MoodTrackerApp/Info.plist"),
        appCategory: .healthcareAndFitness
    )
]
#else
let products: [Product] = [
    .executable(name: "MoodTrackerApp", targets: ["MoodTrackerApp"])
]
#endif

let package = Package(
    name: "MoodTrackerAppPackage",
    platforms: [
        .iOS(.v16)
    ],
    products: products,
    targets: [
        .executableTarget(
            name: "MoodTrackerApp",
            path: "MoodTrackerApp"
        )
    ]
)
