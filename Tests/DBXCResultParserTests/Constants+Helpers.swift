//
//  Constants.swift
//  
//
//  Created by Алексей Берёзка on 30.12.2021.
//

import Foundation
@testable import DBXCResultParser
import XCTest

extension Constants {
    static var resourcesPath: URL {
        get throws {
            try unitTestsReportPath.deletingLastPathComponent()
        }
    }
    
    static var unitTestsReportPath: URL {
        get throws {
            try path(filename: "AllTests", type: "xcresult")
        }
    }
    
    static var unitTestsWithCoverageReportPath: URL {
        get throws {
            try path(filename: "AllTests_coverage", type: "xcresult")
        }
    }
    
    static var e2eTestsReportPath: URL {
        get throws {
            try path(filename: "E2ETests", type: "xcresult")
        }
    }
    
    static private func path(filename: String, type: String) throws -> URL {
        let path = try XCTUnwrap(Bundle.module.path(forResource: filename, ofType: type))
        return try XCTUnwrap(URL(string: path))
    }
}
