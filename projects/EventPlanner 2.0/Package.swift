// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "EventDeskCoreBindings",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "EventDeskCoreBindings", targets: ["EventDeskCoreBindings"])
    ],
    targets: [
        .target(
            name: "CEventDeskCore",
            publicHeadersPath: "include",
            cSettings: [
                // Consumers must ensure the dylib is available at link/runtime
                .define("EDP_USE_DYLIB", to: "1")
            ]
        ),
        .target(
            name: "EventDeskCoreBindings",
            dependencies: ["CEventDeskCore"]
        )
    ]
)
