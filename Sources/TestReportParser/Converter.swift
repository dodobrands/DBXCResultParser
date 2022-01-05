//
//  Converter.swift
//  
//
//  Created by Алексей Берёзка on 30.12.2021.
//

import Foundation

class Converter {
    static func convert(xcresultPath: URL) throws -> OverviewReportDTO {
        let tempFilePath = try tempFilePath
        try Shell.execute("xcrun xcresulttool get --path \(xcresultPath.relativePath) --format json > \(tempFilePath.relativePath)")
        let data = try Data(contentsOf: tempFilePath)
        try FileManager.default.removeItem(atPath: tempFilePath.relativePath)
        let report = try JSONDecoder().decode(OverviewReportDTO.self, from: data)
        return report
    }
    
    static func convertDetailed(xcresultPath: URL, refId: String) throws -> DetailedReportDTO {
        let tempFilePath = try tempFilePath
        try Shell.execute("xcrun xcresulttool get --path \(xcresultPath.relativePath) --format json --id \(refId) > \(tempFilePath.relativePath)")
        let data = try Data(contentsOf: tempFilePath)
        try FileManager.default.removeItem(atPath: tempFilePath.relativePath)
        let report = try JSONDecoder().decode(DetailedReportDTO.self, from: data)
        return report
    }
}

extension Converter {
    static var cachesDirectory: URL {
        get throws {
            guard let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
                throw Error.noCachesDirectory
            }
            
            return cachesDirectory
        }
    }
    
    static var appCachesDirectory: URL {
        get throws {
            let appCachesDirectory = try cachesDirectory.appendingPathComponent("TestReportParser", isDirectory: true)
            if !FileManager.default.fileExists(atPath: appCachesDirectory.path) {
                try FileManager.default.createDirectory(at: appCachesDirectory,
                                                    withIntermediateDirectories: true,
                                                    attributes: nil)
            }
            return appCachesDirectory
        }
    }
    
    static var tempFilePath: URL {
        get throws {
            try appCachesDirectory
                .appendingPathComponent("temp", isDirectory: false)
                .appendingPathExtension("json")
        }
    }
}

extension Converter {
    enum Error: Swift.Error {
        case noCachesDirectory
    }
}
