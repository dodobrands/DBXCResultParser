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

    static var testsReportPaths: [URL] {
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

    /// Returns array of xcresult paths for use in parameterized tests
    /// Returns empty array if paths cannot be loaded (test will be skipped)
    static var testsReportPathsForParameterizedTests: [URL] {
        (try? testsReportPaths) ?? []
    }

    @available(*, deprecated, message: "Use testsReportPaths instead")
    static var testsReportPath: URL {
        get throws {
            // Return the first available xcresult file for backward compatibility
            let paths = try testsReportPaths
            guard let firstPath = paths.first else {
                throw TestError("No xcresult files found in resources")
            }
            return firstPath
        }
    }

    static private func path(filename: String, type: String) throws -> URL {
        guard let path = Bundle.module.path(forResource: filename, ofType: type) else {
            throw TestError("Could not find resource: \(filename).\(type)")
        }
        guard let url = URL(string: path) else {
            throw TestError("Could not create URL from path: \(path)")
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

// Expected values per xcresult file
struct ExpectedReportValues {
    let modulesCount: Int
    let coverageLines: Int
    let filesCount: Int
    let repeatableTestsCount: Int
    let flackyTestsCount: Int
}

struct ExpectedCoverageValues {
    let targetsCount: Int
    let coveredLines: Int
    let executableLines: Int
    let lineCoverage: Double
}

extension Constants {
    static func expectedReportValues(for fileName: String) throws -> ExpectedReportValues {
        switch fileName {
        case "DBXCResultParser.xcresult":
            return ExpectedReportValues(
                modulesCount: 2,
                coverageLines: 481,
                filesCount: 5,
                repeatableTestsCount: 6,
                flackyTestsCount: 2
            )
        case "DBXCResultParser-26.1.1.xcresult":
            return ExpectedReportValues(
                modulesCount: 2,
                coverageLines: 395,
                filesCount: 4,
                repeatableTestsCount: 5,
                flackyTestsCount: 2
            )
        default:
            throw TestError(
                "Unknown xcresult file: \(fileName). Please add expected values for this file.")
        }
    }

    static func expectedCoverageValues(for fileName: String) throws -> ExpectedCoverageValues {
        switch fileName {
        case "DBXCResultParser.xcresult":
            return ExpectedCoverageValues(
                targetsCount: 5,
                coveredLines: 481,
                executableLines: 535,
                lineCoverage: 0.8990654205607477
            )
        case "DBXCResultParser-26.1.1.xcresult":
            return ExpectedCoverageValues(
                targetsCount: 5,
                coveredLines: 395,
                executableLines: 464,
                lineCoverage: 0.8512931034482759
            )
        default:
            throw TestError(
                "Unknown xcresult file: \(fileName). Please add expected values for this file.")
        }
    }
}
