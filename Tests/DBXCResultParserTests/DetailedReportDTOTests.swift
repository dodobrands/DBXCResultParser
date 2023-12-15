//
//  DetailedReportDTOTests.swift
//  
//
//  Created by Алексей Берёзка on 30.12.2021.
//

import Foundation
import XCTest
@testable import DBXCResultParser

class DetailedReportDTOTests: XCTestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
    }
    
    func test_parseWithExplicitRefId() throws {
        let overviewReport = try OverviewReportDTO(from: Constants.unitTestsReportPath)
        XCTAssertNoThrow(try DetailedReportDTO(from: Constants.unitTestsReportPath, refId: overviewReport.testsRefId))
    }
    
    func test_parseWithImplicitRefId() throws {
        XCTAssertNoThrow(try DetailedReportDTO(from: Constants.unitTestsReportPath))
    }
}
