//
//  Constants.swift
//
//
//  Created by Алексей Берёзка on 30.12.2021.
//

import Foundation
import Testing

@testable import DBXCResultParser

struct Constants {
    private static var resourcesPath: URL {
        get throws {
            guard let resourceURL = Bundle.module.resourceURL else {
                throw TestError("Could not find bundle resource URL")
            }
            // When using .copy("Resources"), the Resources folder contents are copied to resourceURL
            // Check if Resources subdirectory exists, otherwise use resourceURL directly
            let resourcesSubdir = resourceURL.appendingPathComponent("Resources")
            if FileManager.default.fileExists(atPath: resourcesSubdir.path) {
                return resourcesSubdir
            }
            // If Resources subdirectory doesn't exist, xcresult files are directly in resourceURL
            return resourceURL
        }
    }

    private static var testsReportPaths: [URL] {
        get throws {
            let resourcesURL = try resourcesPath
            let fileManager = FileManager.default

            guard fileManager.fileExists(atPath: resourcesURL.path) else {
                throw TestError("Resources directory does not exist at: \(resourcesURL.path)")
            }

            guard
                let contents = try? fileManager.contentsOfDirectory(
                    at: resourcesURL,
                    includingPropertiesForKeys: [.isDirectoryKey],
                    options: [.skipsHiddenFiles]
                )
            else {
                throw TestError("Could not read contents of resources directory")
            }

            return contents.filter { url in
                url.pathExtension == "xcresult"
                    && (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
            }.sorted { $0.lastPathComponent < $1.lastPathComponent }
        }
    }

    /// Returns array of xcresult file names for use in parameterized tests
    /// Returns empty array if paths cannot be loaded (test will be skipped)
    static var testsReportFileNames: [String] {
        ((try? testsReportPaths) ?? []).map { $0.lastPathComponent }
    }

    /// Returns URL for a given xcresult file name
    static func url(for fileName: String) throws -> URL {
        let paths = try testsReportPaths
        guard let url = paths.first(where: { $0.lastPathComponent == fileName }) else {
            throw TestError("Could not find xcresult file: \(fileName)")
        }
        return url
    }
}

struct TestError: Error {
    let message: String
    init(_ message: String) {
        self.message = message
    }
}

// Expected coverage values per xcresult file
struct ExpectedReportValues {
    let coveredLines: Int
    let coveragePercentage: Double
    let moduleCoverages: [String: Double]  // Module name -> coverage value
}

// Expected warnings per xcresult file
struct ExpectedWarningsValues {
    let warningCount: Int
    let warnings: [ExpectedWarning]

    struct ExpectedWarning {
        let message: String
        let sourceURL: String
        let className: String
    }
}

extension Constants {
    /// Returns expected coverage values for a given xcresult file name
    /// - Parameter fileName: Name of the xcresult file (read dynamically from file system)
    /// - Returns: Expected coverage values
    /// - Throws: TestError if the file name is unknown
    static func expectedReportValues(for fileName: String) throws -> ExpectedReportValues {
        switch fileName {
        case "DBXCResultParser-15.0.xcresult":
            return ExpectedReportValues(
                coveredLines: 1054,
                coveragePercentage: 0.92039586919104988,
                moduleCoverages: [
                    "DBXCResultParserTests": 0.89906542056074767,
                    "DBXCResultParser-TextFormatterTests": 0.91242038216560506,
                ]
            )
        case "DBXCResultParser-26.1.1.xcresult":
            return ExpectedReportValues(
                coveredLines: 1069,
                coveragePercentage: 0.7650485436893204,
                moduleCoverages: [
                    "DBXCResultParserTests": 0.6991279069767442,
                    "DBXCResultParser-TextFormatterTests": 0.7250308261405672,
                ]
            )
        default:
            throw TestError(
                "Unknown xcresult file: \(fileName). Please add expected values for this file.")
        }
    }

    /// Returns expected warnings count for a given xcresult file name
    /// - Parameter fileName: Name of the xcresult file (read dynamically from file system)
    /// - Returns: Expected warnings count
    /// - Throws: TestError if the file name is unknown
    static func expectedWarningsValues(for fileName: String) throws -> ExpectedWarningsValues {
        switch fileName {
        case "DBXCResultParser-15.0.xcresult":
            return ExpectedWarningsValues(warningCount: 0, warnings: [])
        case "DBXCResultParser-26.1.1.xcresult":
            return ExpectedWarningsValues(
                warningCount: 1,
                warnings: [
                    ExpectedWarningsValues.ExpectedWarning(
                        message: "Some warning to appear in xcresult",
                        sourceURL:
                            "file:///Users/alldmeat/Developer/DBXCResultParser/Tests/DBXCResultParserTests/GenerateXCResultTests.swift",
                        className: "DVTTextDocumentLocation"
                    )
                ]
            )
        default:
            throw TestError(
                "Unknown xcresult file: \(fileName). Please add expected warnings values for this file."
            )
        }
    }
}
