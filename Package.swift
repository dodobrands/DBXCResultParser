// swift-tools-version:6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let packageName = "peekiesdk"

let parserLibraryName = packageName
let executableLibraryName = "peekie"
let testHelpersLibraryName = "PeekieTestHelpers"

let parserTargetName = parserLibraryName
let executableTargetName = executableLibraryName
let testHelpersTargetName = testHelpersLibraryName

let parserTestsTargetName = parserTargetName + "Tests"

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
            name: testHelpersLibraryName,
            targets: [
                testHelpersTargetName
            ]
        ),
        .executable(
            name: executableLibraryName,
            targets: [
                executableTargetName
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
        .package(
            url: "https://github.com/pointfreeco/swift-snapshot-testing.git",
            .upToNextMajor(from: "1.16.0")
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
            path: "Sources/PeekieSDK",
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .treatAllWarnings(as: .error),
            ]
        ),
        .executableTarget(
            name: executableTargetName,
            dependencies: [
                .init(stringLiteral: parserTargetName),
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
                .product(
                    name: "SnapshotTesting",
                    package: "swift-snapshot-testing"
                ),
            ],
            path: "Tests/PeekieTests",
            exclude: [
                "__Snapshots__"
            ],
            resources: [
                .copy("Resources")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
    ]
)
