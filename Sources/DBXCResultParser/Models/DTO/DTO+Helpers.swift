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
    }
}
