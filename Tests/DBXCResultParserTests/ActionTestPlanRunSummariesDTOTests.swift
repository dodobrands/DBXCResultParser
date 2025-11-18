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
    func test_parseWithExplicitRefId() async throws {
        let overviewReport = try await ActionsInvocationRecordDTO(from: Constants.testsReportPath)
        _ = try await ActionTestPlanRunSummariesDTO(
            from: Constants.testsReportPath, refId: try overviewReport.testsRefId)
    }

    @Test
    func test_parseWithImplicitRefId() async throws {
        _ = try await ActionTestPlanRunSummariesDTO(from: Constants.testsReportPath)
    }
}
