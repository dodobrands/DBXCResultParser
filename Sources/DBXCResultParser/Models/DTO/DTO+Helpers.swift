//
//  DTO+Helpers.swift
//
//
//  Created by Алексей Берёзка on 30.12.2021.
//

import Foundation

extension ActionsInvocationRecordDTO {
    init(from xcresultPath: URL) throws {
        let command =
            "xcrun xcresulttool get --legacy --path '\(xcresultPath.relativePath)' --format json"
        let output = try DBShell.execute(command)
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
    init(from xcresultPath: URL, refId: String? = nil) throws {
        let refId = try (refId ?? ActionsInvocationRecordDTO(from: xcresultPath).testsRefId)
        let command =
            "xcrun xcresulttool get --legacy --path '\(xcresultPath.relativePath)' --format json --id '\(refId)'"
        let output = try DBShell.execute(command)
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
    init(from xcresultPath: URL, refId: String? = nil) throws {
        let refId = try (refId ?? ActionsInvocationRecordDTO(from: xcresultPath).testsRefId)
        let command =
            "xcrun xcresulttool get --legacy --path '\(xcresultPath.relativePath)' --format json --id '\(refId)'"
        let output = try DBShell.execute(command)
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
    init(from xcresultPath: URL) throws {
        let command =
            "xcrun xccov view --report --only-targets --json '\(xcresultPath.relativePath)'"
        let output = try DBShell.execute(command)
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
