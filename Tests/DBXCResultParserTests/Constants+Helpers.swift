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
            try testsReportPath.deletingLastPathComponent()
        }
    }
    
    static var testsReportPath: URL {
        get throws {
            try path(filename: "DBXCResultParser", type: "xcresult")
        }
    }
    
    static private func path(filename: String, type: String) throws -> URL {
        let path = try XCTUnwrap(Bundle.module.path(forResource: filename, ofType: type))
        return try XCTUnwrap(URL(string: path))
    }
}
