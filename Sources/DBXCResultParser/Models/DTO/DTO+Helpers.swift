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
                // Parse as array of coverage objects
                let coverageData = try JSONDecoder().decode(Array<CoverageDTO>.self, from: data)
                // Filter to only targets (exclude test bundles)
                self = coverageData.filter { !$0.name.hasSuffix("Tests") }
            } catch {
                // If both methods fail, return empty array (coverage not available)
                // This allows the parser to continue without coverage data
                self = []
            }
        }
    }
}
