//
//  ActionTestPlanRunSummariesDTOTests.swift
//
//
//  Created by Алексей Берёзка on 30.12.2021.
//

import Foundation
import Testing

@testable import DBXCResultParser

@Suite
struct ActionTestPlanRunSummariesDTOTests {

    @Test
    func test_parseWithExplicitRefId() throws {
        let overviewReport = try ActionsInvocationRecordDTO(from: Constants.testsReportPath)
        _ = try ActionTestPlanRunSummariesDTO(
            from: Constants.testsReportPath, refId: overviewReport.testsRefId)
    }

    @Test
    func test_parseWithImplicitRefId() throws {
        _ = try ActionTestPlanRunSummariesDTO(from: Constants.testsReportPath)
    }
}
