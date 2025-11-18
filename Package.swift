// swift-tools-version:6.2
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
                formatterTargetName,
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
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-argument-parser.git",
            .upToNextMajor(from: "1.0.0")
        ),
        .package(
            url: "https://github.com/swiftlang/swift-subprocess.git",
            .upToNextMinor(from: "0.2.1")
        ),
    ],
    targets: [
        .target(
            name: parserTargetName,
            dependencies: [
                .product(
                    name: "ArgumentParser",
                    package: "swift-argument-parser"
                ),
                .product(
                    name: "Subprocess",
                    package: "swift-subprocess"
                ),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .treatAllWarnings(as: .error),
            ]
        ),
        .target(
            name: formatterTargetName,
            dependencies: [
                .init(stringLiteral: parserTargetName)
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .treatAllWarnings(as: .error),
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
                ),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .treatAllWarnings(as: .error),
            ]
        ),
        .target(
            name: testHelpersTargetName,
            dependencies: [
                .init(stringLiteral: parserTargetName)
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .treatAllWarnings(as: .error),
            ]
        ),
        .testTarget(
            name: parserTestsTargetName,
            dependencies: [
                .init(stringLiteral: parserTargetName),
                .init(stringLiteral: testHelpersTargetName),
            ],
            resources: [
                .copy("Resources")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .treatAllWarnings(as: .error),
            ]
        ),
        .testTarget(
            name: formatterTestsTargetName,
            dependencies: [
                .init(stringLiteral: formatterTargetName),
                .init(stringLiteral: testHelpersTargetName),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .treatAllWarnings(as: .error),
            ]
        ),
    ]
)
