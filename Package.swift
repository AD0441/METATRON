// swift-tools-version: 6.2
import PackageDescription
let package = Package(
    name: "METATRON", defaultLocalization: "es", platforms: [.macOS(.v14)],
    products: [.library(name:"MetatronCore",targets:["MetatronCore"]), .library(name:"MetatronWorkflow",targets:["MetatronWorkflow"]), .executable(name: "METATRON", targets: ["Metatron"]), .executable(name: "metatron-cli", targets: ["MetatronCLI"])],
    targets: [
        .target(name: "MetatronCore", swiftSettings: [.swiftLanguageMode(.v5)]),
        .target(name: "MetatronWorkflow", dependencies: ["MetatronCore"], swiftSettings: [.swiftLanguageMode(.v6), .enableUpcomingFeature("NonisolatedNonsendingByDefault")]),
        .executableTarget(name: "Metatron", dependencies: ["MetatronCore", "MetatronWorkflow"], swiftSettings: [.swiftLanguageMode(.v6), .defaultIsolation(MainActor.self), .enableUpcomingFeature("NonisolatedNonsendingByDefault")]),
        .executableTarget(name: "MetatronCLI", dependencies: ["MetatronCore", "MetatronWorkflow"], swiftSettings: [.swiftLanguageMode(.v6)]),
        .testTarget(name: "MetatronCoreTests", dependencies: ["MetatronCore"], swiftSettings: [.swiftLanguageMode(.v5)]),
        .testTarget(name: "MetatronWorkflowTests", dependencies: ["MetatronWorkflow", "MetatronCore"], swiftSettings: [.swiftLanguageMode(.v6)])
    ]
)
