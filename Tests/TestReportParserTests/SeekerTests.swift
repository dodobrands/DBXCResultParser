//
//  ReportSeekerTests.swift
//  
//
//  Created by Алексей Берёзка on 30.12.2021.
//

import Foundation
import XCTest
@testable import TestReportParser

class SeekerTests: XCTestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
    }
    
    func test_xcresultIsFound() throws {
        let resourcesPath = try Constants.resourcesPath
        let result = try XCTUnwrap(XCResultSeeker().seek(in: resourcesPath).first)
        XCTAssertEqual(result.pathExtension, "xcresult")
    }
}
