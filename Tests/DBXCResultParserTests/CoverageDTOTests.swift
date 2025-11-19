// Created by Yaroslav Bredikhin on 06.09.2022

import DBXCResultParserTestHelpers
import Foundation
import Testing

@testable import DBXCResultParser

@Suite
struct CoverageDTOTests {

    @Test(arguments: Constants.testsReportFileNamesForParameterizedTests)
    func test_coverageDtoParse(fileName: String) async throws {
        let reportPath = try Constants.url(for: fileName)
        _ = try await [CoverageDTO](from: reportPath)
    }

    @Test(arguments: Constants.testsReportFileNamesForParameterizedTests)
    func test_coverageDtoData(fileName: String) async throws {
        let reportPath = try Constants.url(for: fileName)
        let result = try await [CoverageDTO](from: reportPath)
        let expected = try Constants.expectedCoverageValues(for: fileName)

        // Basic validation for all files
        #expect(!result.isEmpty)

        // Detailed validation for all files
        #expect(result.count == expected.targetsCount)

        let expectedResult = CoverageDTO.testMake(
            coveredLines: expected.coveredLines,
            executableLines: expected.executableLines,
            lineCoverage: expected.lineCoverage,
            name: "DBXCResultParser"
        )

        let target = try #require(result.first(where: { $0.name == expectedResult.name }))

        #expect(target.coveredLines == expectedResult.coveredLines)
        #expect(target.executableLines == expectedResult.executableLines)
        #expect(target.lineCoverage == expectedResult.lineCoverage)
    }
}
