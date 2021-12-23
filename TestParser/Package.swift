// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TestParser",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "TestParser",
            targets: ["TestParser"]),
    ],
    dependencies: [
        .package(url: "https://github.com/MaxDesiatov/XMLCoder.git", from: "0.12.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "TestParser",
            dependencies: ["XMLCoder"]),
        .testTarget(
            name: "TestParserTests",
            dependencies: ["TestParser"],
            resources: [.process("report.json"),
                        .process("reportUnitsSuccess.json"),
                        .process("reportUnitsFailure.json"),
                        .process("report.junit"),
                        .process("reportUnitsWithoutErrors.json"),
                        .process("testsRefFileMixed.json")
            ]),
    ]
)

