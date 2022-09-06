// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let packageName = "TestReportParser"
let packageTestsName = packageName + "Tests"

let package = Package(
    name: packageName,
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: packageName,
            targets: [packageName]),
    ],
    dependencies: [

    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: packageName,
            dependencies: [

            ]
        ),
        .testTarget(
            name: packageTestsName,
            dependencies: [.init(stringLiteral: packageName)],
            resources: [
                .process("Resources/AllTests.xcresult"),
                .process("Resources/AllTests_coverage.xcresult"),
                .process("Resources/E2ETests.xcresult")
            ]
        ),
    ]
)

