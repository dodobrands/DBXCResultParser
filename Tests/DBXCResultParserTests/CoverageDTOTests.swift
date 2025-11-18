// Created by Yaroslav Bredikhin on 06.09.2022

import DBXCResultParserTestHelpers
import Foundation
import Testing

@testable import DBXCResultParser

@Suite
struct CoverageDTOTests {

    @Test
    func test_coverageDtoParse() throws {
        _ = try [CoverageDTO](from: Constants.testsReportPath)
    }

    @Test
    func test_coverageDtoData() throws {
        let result = try [CoverageDTO](from: Constants.testsReportPath)
        #expect(result.count == 5)  // as targets count
        let expectedResult = CoverageDTO.testMake(
            coveredLines: 481,
            executableLines: 535,
            lineCoverage: 0.8990654205607477,
            name: "DBXCResultParser"
        )

        let target = try #require(result.first(where: { $0.name == expectedResult.name }))

        #expect(target.coveredLines == expectedResult.coveredLines)
        #expect(target.executableLines == expectedResult.executableLines)
        #expect(target.lineCoverage == expectedResult.lineCoverage)
    }
}
