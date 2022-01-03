//
//  ReportConverter.swift
//  
//
//  Created by Алексей Берёзка on 30.12.2021.
//

import Foundation

class ReportConverter {
    static func convert(xcresultPath: URL) throws -> OverviewReportDTO {
        let tempPath = xcresultPath.nearbyTempFileURL
        try Shell.execute("xcrun xcresulttool get --path \(xcresultPath.relativePath) --format json > \(tempPath.relativePath)")
        let data = try Data(contentsOf: tempPath)
        try FileManager.default.removeItem(atPath: tempPath.relativePath)
        let report = try JSONDecoder().decode(OverviewReportDTO.self, from: data)
        return report
    }
    
    static func convertDetailed(xcresultPath: URL, refId: String) throws -> DetailedReportDTO {
        let tempPath = xcresultPath.nearbyTempFileURL
        try Shell.execute("xcrun xcresulttool get --path \(xcresultPath.relativePath) --format json --id \(refId) > \(tempPath.relativePath)")
        let data = try Data(contentsOf: tempPath)
        try FileManager.default.removeItem(atPath: tempPath.relativePath)
        let report = try JSONDecoder().decode(DetailedReportDTO.self, from: data)
        return report
    }
}

extension URL {
    var nearbyTempFileURL: URL {
        deletingLastPathComponent().appendingPathComponent("temp.json")
    }
}
