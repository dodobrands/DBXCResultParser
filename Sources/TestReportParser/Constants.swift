//
//  Constants.swift
//  
//
//  Created by Алексей Берёзка on 05.01.2022.
//

import Foundation

struct Constants {
    private static let packageName = "TestReportParser"
    
    private static var cachesDirectory: URL {
        get throws {
            guard let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
                throw Error.noCachesDirectory
            }
            
            return cachesDirectory
        }
    }
    
    private static var appCachesDirectory: URL {
        get throws {
            let appCachesDirectory = try cachesDirectory.appendingPathComponent(packageName, isDirectory: true)
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

extension Constants {
    enum Error: Swift.Error {
        case noCachesDirectory
    }
}
