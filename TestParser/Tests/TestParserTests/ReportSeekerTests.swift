//
//  ReportSeekerTests.swift
//  
//
//  Created by Алексей Берёзка on 30.12.2021.
//

import Foundation
import XCTest
@testable import TestParser

class ReportSeekerTests: XCTestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
    }
    
    func test_xcresultIsFound() throws {
        let resourcesPath = try XCTUnwrap(TestsConstants.resourcesPath)
        let result = try XCTUnwrap(ReportSeeker.seek(in: resourcesPath).first)
        XCTAssertEqual(result.pathExtension, "xcresult")
    }
}
