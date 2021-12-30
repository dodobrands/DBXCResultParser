//
//  ReportConverter.swift
//  
//
//  Created by Алексей Берёзка on 30.12.2021.
//

import Foundation

class ReportConverter {
    static func convert(sourcePath: URL, resultPath: URL) throws {
        try Shell.execute("xcrun xcresulttool get --path \(sourcePath.relativePath) --format json > \(resultPath.relativePath)")
    }
}
