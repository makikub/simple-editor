// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "simple-editor",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "simple-editor", targets: ["SimpleEditorApp"])
    ],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.9.3")
    ],
    targets: [
        .executableTarget(
            name: "SimpleEditorApp",
            dependencies: [
                .product(name: "Sparkle", package: "Sparkle")
            ],
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug)),
                .define("RELEASE", .when(configuration: .release))
            ],
            linkerSettings: [
                .unsafeFlags([
                    "-Xlinker", "-rpath",
                    "-Xlinker", "@executable_path/../Frameworks"
                ], .when(platforms: [.macOS]))
            ]
        )
    ],
    swiftLanguageModes: [.v5]
)
