//
//  ActionTestPlanRunSummariesDTOTests.swift
//
//
//  Created by Алексей Берёзка on 30.12.2021.
//

import Foundation
import XCTest

@testable import DBXCResultParser

class ActionTestPlanRunSummariesDTOTests: XCTestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
    }

    func test_parseWithExplicitRefId() throws {
        let overviewReport = try ActionsInvocationRecordDTO(from: Constants.testsReportPath)
        XCTAssertNoThrow(
            try ActionTestPlanRunSummariesDTO(
                from: Constants.testsReportPath, refId: overviewReport.testsRefId))
    }

    func test_parseWithImplicitRefId() throws {
        XCTAssertNoThrow(try ActionTestPlanRunSummariesDTO(from: Constants.testsReportPath))
    }
}
