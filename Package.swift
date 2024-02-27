// swift-tools-version:5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let packageName = "DBXCResultParser"

let parserLibraryName = packageName
let formatterLibraryName = parserLibraryName + "-TextFormatter"
let executableFormatterLibraryName = formatterLibraryName + "Exec"
let testHelpersLibraryName = parserLibraryName + "TestHelpers"

let parserTargetName = parserLibraryName
let formatterTargetName = formatterLibraryName
let executableFormatterTargetName = formatterTargetName + "Exec"
let testHelpersTargetName = testHelpersLibraryName

let parserTestsTargetName = parserTargetName + "Tests"
let formatterTestsTargetName = formatterTargetName + "Tests"


let package = Package(
    name: packageName,
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: parserLibraryName, 
            targets: [
                parserTargetName
            ]
        ),
        .library(
            name: formatterLibraryName, 
            targets: [
                parserTargetName,
                formatterTargetName
            ]
        ),
        .library(
            name: testHelpersLibraryName, 
            targets: [
                testHelpersLibraryName
            ]
        ),
        .executable(
            name: executableFormatterLibraryName,
            targets: [
                executableFormatterTargetName
            ]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-argument-parser.git",
            .upToNextMajor(from: "1.0.0")
        ),
    ],
    targets: [
        .target(
            name: parserTargetName,
            dependencies: [
                .product(
                    name: "ArgumentParser",
                    package: "swift-argument-parser"
                )
            ]
        ),
        .target(
            name: formatterTargetName,
            dependencies: [
                .init(stringLiteral: parserTargetName)
            ]
        ),
        .executableTarget(
            name: executableFormatterTargetName,
            dependencies: [
                .init(stringLiteral: parserTargetName),
                .init(stringLiteral: formatterTargetName),
                .product(
                    name: "ArgumentParser",
                    package: "swift-argument-parser"
                )
            ]
        ),
        .target(
            name: testHelpersTargetName, 
            dependencies: [
                .init(stringLiteral: parserTargetName)
            ]
        ),
        .testTarget(
            name: parserTestsTargetName,
            dependencies: [
                .init(stringLiteral: parserTargetName),
                .init(stringLiteral: testHelpersTargetName)
            ],
            resources: [
                .copy("Resources/DBXCResultParser.xcresult")
            ]
        ),
        .testTarget(
            name: formatterTestsTargetName,
            dependencies: [
                .init(stringLiteral: formatterTargetName),
                .init(stringLiteral: testHelpersTargetName)
            ]
        )
    ]
)

