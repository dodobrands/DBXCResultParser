// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TestReportParser",
    platforms: [
        .macOS(.v10_13)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "TestReportParser",
            targets: ["TestReportParser"]),
    ],
    dependencies: [
//        .package(url: "https://github.com/MaxDesiatov/XMLCoder.git", from: "0.12.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "TestReportParser",
            dependencies: [
//                "XMLCoder"
            ]),
        .testTarget(
            name: "TestReportParserTests",
            dependencies: ["TestReportParser"],
            resources: [
                .process("Resources/report.json"),
                .process("Resources/reportUnitsSuccess.json"),
                .process("Resources/reportUnitsFailure.json"),
                .process("Resources/report.junit"),
                .process("Resources/reportUnitsWithoutErrors.json"),
                .process("Resources/testsRefFileMixed.json"),
                .process("Resources/AllTests.xcresult"),
                .process("Resources/E2ETests.xcresult")
            ]),
    ]
)

