//
//  DetailedReportDTOTests.swift
//  
//
//  Created by Алексей Берёзка on 30.12.2021.
//

import Foundation
import XCTest
@testable import TestReportParser

class DetailedReportDTOTests: XCTestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
    }
    
    func test() throws {
        let overviewReport = try OverviewReportDTO(from: TestsConstants.unitTestsReportPath)
        XCTAssertNoThrow(try DetailedReportDTO(from: TestsConstants.unitTestsReportPath, refId: overviewReport.testsRefId))
    }
}
