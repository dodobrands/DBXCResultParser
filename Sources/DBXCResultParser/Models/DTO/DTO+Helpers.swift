//
//  DTO+Helpers.swift
//
//
//  Created by Алексей Берёзка on 30.12.2021.
//

import Foundation

extension TestResultsDTO {
    init(from xcresultPath: URL) async throws {
        let output = try await DBShell.execute(
            "xcrun",
            arguments: [
                "xcresulttool", "get", "test-results", "tests",
                "--path", xcresultPath.relativePath,
                "--compact",
            ]
        )
        guard let data = output.data(using: .utf8) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: [],
                    debugDescription: "Failed to convert output to Data"
                )
            )
        }
        self = try JSONDecoder().decode(TestResultsDTO.self, from: data)
    }
}

extension Array where Element == CoverageDTO {
    init(from xcresultPath: URL) async throws {
        // Try xccov first (works for newer xcresult files)
        do {
            let output = try await DBShell.execute(
                "xcrun",
                arguments: [
                    "xccov", "view", "--report", "--only-targets", "--json",
                    xcresultPath.relativePath,
                ]
            )
            guard let data = output.data(using: .utf8) else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: [],
                        debugDescription: "Failed to convert output to Data"
                    )
                )
            }
            self = try JSONDecoder().decode(Array<CoverageDTO>.self, from: data)
        } catch {
            // For older xcresult files, try without --only-targets flag
            // This may work for files that have coverage but can't be loaded with --only-targets
            do {
                let output = try await DBShell.execute(
                    "xcrun",
                    arguments: [
                        "xccov", "view", "--report", "--json",
                        xcresultPath.relativePath,
                    ]
                )
                guard let data = output.data(using: .utf8) else {
                    throw DecodingError.dataCorrupted(
                        DecodingError.Context(
                            codingPath: [],
                            debugDescription: "Failed to convert output to Data"
                        )
                    )
                }
                // Parse as TotalCoverageDTO (object with lineCoverage at root level)
                let totalCoverage = try JSONDecoder().decode(TotalCoverageDTO.self, from: data)
                // Filter to only targets (exclude test bundles)
                self = totalCoverage.targets.filter { !$0.name.hasSuffix("Tests") }
            } catch {
                // If both methods fail, return empty array (coverage not available)
                // This allows the parser to continue without coverage data
                self = []
            }
        }
    }
}

extension TotalCoverageDTO {
    init(from xcresultPath: URL) async throws {
        let output = try await DBShell.execute(
            "xcrun",
            arguments: [
                "xccov", "view", "--report", "--json",
                xcresultPath.relativePath,
            ]
        )
        guard let data = output.data(using: .utf8) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: [],
                    debugDescription: "Failed to convert output to Data"
                )
            )
        }
        self = try JSONDecoder().decode(TotalCoverageDTO.self, from: data)
    }
}

extension BuildResultsDTO {
    init(from xcresultPath: URL) async throws {
        let output = try await DBShell.execute(
            "xcrun",
            arguments: [
                "xcresulttool", "get", "build-results",
                "--path", xcresultPath.relativePath,
                "--compact",
            ]
        )

        // If output is empty, build-results are not available (e.g., test-only xcresult)
        guard !output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: [],
                    debugDescription: "Build results not available in this xcresult file"
                )
            )
        }

        guard let data = output.data(using: .utf8) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: [],
                    debugDescription: "Failed to convert output to Data"
                )
            )
        }
        var decoded = try JSONDecoder().decode(BuildResultsDTO.self, from: data)
        // Filter warnings to include only "Swift Compiler Warning" (exclude "Swift Compiler Error" duplicates)
        decoded = BuildResultsDTO(
            warnings: decoded.warnings.filter { $0.issueType == "Swift Compiler Warning" }
        )
        self = decoded
    }
}
