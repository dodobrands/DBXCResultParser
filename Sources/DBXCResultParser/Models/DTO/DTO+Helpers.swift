//
//  DTO+Helpers.swift
//  
//
//  Created by Алексей Берёзка on 30.12.2021.
//

import Foundation

extension ActionsInvocationRecordDTO {
    init(from xcresultPath: URL) throws {
        let filePath = try Constants.actionsInvocationRecord
        try DBShell.execute("xcrun xcresulttool get --path \(xcresultPath.relativePath) --format json > \(filePath.relativePath)")
        let data = try Data(contentsOf: filePath)
        try FileManager.default.removeItem(atPath: filePath.relativePath)
        self = try JSONDecoder().decode(ActionsInvocationRecordDTO.self, from: data)
    }
}

extension ActionTestPlanRunSummariesDTO {
    init(from xcresultPath: URL, refId: String? = nil) throws {
        let refId = try (refId ?? ActionsInvocationRecordDTO(from: xcresultPath).testsRefId)
        let filePath = try Constants.actionTestPlanRunSummaries
        try DBShell.execute("xcrun xcresulttool get --path \(xcresultPath.relativePath) --format json --id \(refId) > \(filePath.relativePath)")
        let data = try Data(contentsOf: filePath)
        try FileManager.default.removeItem(atPath: filePath.relativePath)
        self = try JSONDecoder().decode(ActionTestPlanRunSummariesDTO.self, from: data)
    }
}

extension Array where Element == CoverageDTO {
    init(from xcresultPath: URL) throws {
        let tempFilePath = try Constants.actionsInvocationRecord
        try DBShell.execute("xcrun xccov view --report --only-targets --json \(xcresultPath.relativePath) > \(tempFilePath.relativePath)")
        let data = try Data(contentsOf: tempFilePath)
        try FileManager.default.removeItem(atPath: tempFilePath.relativePath)
        self = try JSONDecoder().decode(Array<CoverageDTO>.self, from: data)
    }
}
