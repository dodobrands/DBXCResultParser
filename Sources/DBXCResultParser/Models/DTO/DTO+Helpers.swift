//
//  DTO+Helpers.swift
//  
//
//  Created by Алексей Берёзка on 30.12.2021.
//

import Foundation

extension OverviewReportDTO {
    init(from xcresultPath: URL) throws {
        let tempFilePath = try Constants.tempFilePath
        try Shell.execute("xcrun xcresulttool get --path \(xcresultPath.relativePath) --format json > \(tempFilePath.relativePath)")
        let data = try Data(contentsOf: tempFilePath)
        try FileManager.default.removeItem(atPath: tempFilePath.relativePath)
        self = try JSONDecoder().decode(OverviewReportDTO.self, from: data)
    }
}

extension DetailedReportDTO {
    init(from xcresultPath: URL, refId: String? = nil) throws {
        let refId = try (refId ?? OverviewReportDTO(from: xcresultPath).testsRefId)
        let tempFilePath = try Constants.tempFilePath
        try Shell.execute("xcrun xcresulttool get --path \(xcresultPath.relativePath) --format json --id \(refId) > \(tempFilePath.relativePath)")
        let data = try Data(contentsOf: tempFilePath)
        try FileManager.default.removeItem(atPath: tempFilePath.relativePath)
        self = try JSONDecoder().decode(DetailedReportDTO.self, from: data)
    }
}

extension Array where Element == CoverageDTO {
    init(from xcresultPath: URL) throws {
        let tempFilePath = try Constants.tempFilePath
        try Shell.execute("xcrun xccov view --report --only-targets --json \(xcresultPath.relativePath) > \(tempFilePath.relativePath)")
        let data = try Data(contentsOf: tempFilePath)
        try FileManager.default.removeItem(atPath: tempFilePath.relativePath)
        self = try JSONDecoder().decode(Array<CoverageDTO>.self, from: data)
    }
}
