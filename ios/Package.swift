// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ChipmunkCareRules",
    platforms: [.macOS(.v13)],
    products: [.library(name: "CareProgressRules", targets: ["CareProgressRules"])],
    targets: [
        .target(
            name: "CareProgressRules",
            path: "HerHealthLearning",
            exclude: ["App.swift", "ContentView.swift"],
            sources: ["CareProgressRules.swift"]
        ),
        .testTarget(
            name: "CareProgressRulesTests",
            dependencies: ["CareProgressRules"],
            path: "ChipmunkTests"
        )
    ]
)
