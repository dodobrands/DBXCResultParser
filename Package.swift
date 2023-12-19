// swift-tools-version:5.3
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
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: packageName,
            targets: [packageName]
        ),
        .library(
            name: packageTestHelpersName,
            targets: [packageTestHelpersName]
        ),
    ],
    dependencies: [

    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: packageName,
            dependencies: []
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
                .process("Resources/DBXCResultParser.xcresult")
            ]
        ),
    ]
)

