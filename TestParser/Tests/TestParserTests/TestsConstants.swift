//
//  TestsConstants.swift
//  
//
//  Created by Алексей Берёзка on 30.12.2021.
//

import Foundation
@testable import TestParser
import XCTest

struct TestsConstants {
    private static var projectPath: URL {
        get throws {
            try XCTUnwrap(
                Process()
                    .currentDirectoryURL?
                    .deletingLastPathComponent()
                    .deletingLastPathComponent()
                    .deletingLastPathComponent()
                    .deletingLastPathComponent()
                    .deletingLastPathComponent()
            )
        }
    }
    
    static var resourcesPath: URL {
        get throws {
            try projectPath.appendingPathComponent("TestParser/Tests/TestParserTests/Resources")
        }
    }
    
    static var unitTestsReportPath: URL {
        get throws {
            try path(of: "AllTests")
        }
    }
    
    static var e2eTestsReportPath: URL {
        get throws {
            try path(of: "E2ETests")
        }
    }
    
    private static func path(of reportName: String) throws -> URL {
        let path = try XCTUnwrap(resourcesPath)
        return try XCTUnwrap(ReportSeeker.seek(in: path).first { $0.deletingPathExtension().lastPathComponent == reportName })
    }
}
