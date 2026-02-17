// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SwiftUIDiagnosticsKit",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "SwiftUIDiagnosticsKit",
            targets: ["SwiftUIDiagnosticsKit"]
        ),
    ],
    targets: [
        .target(
            name: "SwiftUIDiagnosticsKit",
            path: "Sources/SwiftUIDiagnosticsKit",
            swiftSettings: [
                .define("SWIFTUI_DIAGNOSTICS", .when(configuration: .debug))
            ]
        ),
        .testTarget(
            name: "SwiftUIDiagnosticsKitTests",
            dependencies: ["SwiftUIDiagnosticsKit"],
            path: "Tests/SwiftUIDiagnosticsKitTests"
        ),
    ]
)
