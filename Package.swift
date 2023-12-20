// swift-tools-version:5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let packageName = "DBXCResultParser"
let packageTestsName = packageName + "Tests"
let packageTestHelpersName = packageName + "TestHelpers"

let package = Package(
    name: packageName,
    platforms: [
        .macOS(.v10_15)
    ],
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-argument-parser.git",
            .upToNextMajor(from: "1.0.0")
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .executableTarget(
            name: packageName,
            dependencies: [
                .product(
                    name: "ArgumentParser",
                    package: "swift-argument-parser"
                )
            ]
        ),
        .target(
            name: packageTestHelpersName, 
            dependencies: [
                .init(stringLiteral: packageName)
            ]
        ),
        .testTarget(
            name: packageTestsName,
            dependencies: [
                .init(stringLiteral: packageName),
                .init(stringLiteral: packageTestHelpersName)
            ],
            resources: [
                .copy("Resources/DBXCResultParser.xcresult")
            ]
        ),
    ]
)

