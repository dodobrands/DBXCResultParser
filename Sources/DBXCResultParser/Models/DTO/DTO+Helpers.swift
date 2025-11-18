//
//  DTO+Helpers.swift
//
//
//  Created by Алексей Берёзка on 30.12.2021.
//

import Foundation

extension ActionsInvocationRecordDTO {
    init(from xcresultPath: URL) async throws {
        let output = try await DBShell.shared.execute(
            "xcrun",
            arguments: [
                "xcresulttool", "get", "--legacy",
                "--path", xcresultPath.relativePath,
                "--format", "json",
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
        self = try JSONDecoder().decode(ActionsInvocationRecordDTO.self, from: data)
    }
}

extension ActionTestPlanRunSummariesDTO {
    init(from xcresultPath: URL, refId: String? = nil) async throws {
        let finalRefId: String
        if let providedRefId = refId {
            finalRefId = providedRefId
        } else {
            let record = try await ActionsInvocationRecordDTO(from: xcresultPath)
            finalRefId = try record.testsRefId
        }
        let output = try await DBShell.shared.execute(
            "xcrun",
            arguments: [
                "xcresulttool", "get", "--legacy",
                "--path", xcresultPath.relativePath,
                "--format", "json",
                "--id", finalRefId,
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
        self = try JSONDecoder().decode(ActionTestPlanRunSummariesDTO.self, from: data)
    }
}

extension ActionTestSummaryDTO {
    init(from xcresultPath: URL, refId: String? = nil) async throws {
        let finalRefId: String
        if let providedRefId = refId {
            finalRefId = providedRefId
        } else {
            let record = try await ActionsInvocationRecordDTO(from: xcresultPath)
            finalRefId = try record.testsRefId
        }
        let output = try await DBShell.shared.execute(
            "xcrun",
            arguments: [
                "xcresulttool", "get", "--legacy",
                "--path", xcresultPath.relativePath,
                "--format", "json",
                "--id", finalRefId,
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
        self = try JSONDecoder().decode(ActionTestSummaryDTO.self, from: data)
    }
}

extension Array where Element == CoverageDTO {
    init(from xcresultPath: URL) async throws {
        let output = try await DBShell.shared.execute(
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
