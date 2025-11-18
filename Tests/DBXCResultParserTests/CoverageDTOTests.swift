// Created by Yaroslav Bredikhin on 06.09.2022

import DBXCResultParserTestHelpers
import Foundation
import XCTest

@testable import DBXCResultParser

class CoverageDTOTests: XCTestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
    }

    func test_coverageDtoParse() throws {
        XCTAssertNoThrow(try [CoverageDTO](from: Constants.testsReportPath))
    }

    func test_coverageDtoData() throws {
        let result = try [CoverageDTO](from: Constants.testsReportPath)
        XCTAssertEqual(result.count, 5)  // as targets count
        let expectedResult = CoverageDTO.testMake(
            coveredLines: 481,
            executableLines: 535,
            lineCoverage: 0.8990654205607477,
            name: "DBXCResultParser"
        )

        let target = try XCTUnwrap(result.first { $0.name == expectedResult.name })

        XCTAssertEqual(target.coveredLines, expectedResult.coveredLines)
        XCTAssertEqual(target.executableLines, expectedResult.executableLines)
        XCTAssertEqual(target.lineCoverage, expectedResult.lineCoverage)
    }
}
