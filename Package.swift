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
    targets: [
        .executableTarget(
            name: "SimpleEditorApp",
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug)),
                .define("RELEASE", .when(configuration: .release))
            ]
        )
    ],
    swiftLanguageModes: [.v5]
)
