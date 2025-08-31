// swift-tools-version:5.9
import PackageDescription
import Foundation

// Compute absolute paths for rust-core target folders relative to this Package.swift file
let packageDir = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
let rustUniversalPath = packageDir.appendingPathComponent("../../rust-core/target/universal").standardized.path

let package = Package(
    name: "EventDeskProApp",
    platforms: [ .macOS(.v13) ],
    products: [ .executable(name: "EventDeskProApp", targets: ["EventDeskProApp"]) ],
    dependencies: [
        .package(name: "EventDeskCoreBindings", path: "../../")
    ],
    targets: [
        .executableTarget(
            name: "EventDeskProApp",
            dependencies: [
                .product(name: "EventDeskCoreBindings", package: "EventDeskCoreBindings")
            ],
            path: "Sources",
            resources: [
                .process("Resources")
            ],
            linkerSettings: [
                .unsafeFlags([
                    "-L", rustUniversalPath,
                    "-leventdesk_core"
                ])
            ]
        ),
        .testTarget(
            name: "EventDeskProAppTests",
            dependencies: [.product(name: "EventDeskCoreBindings", package: "EventDeskCoreBindings")],
            path: "Tests"
        )
    ]
)
