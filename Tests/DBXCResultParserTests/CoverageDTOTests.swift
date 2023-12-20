// Created by Yaroslav Bredikhin on 06.09.2022

import Foundation
import XCTest
@testable import DBXCResultParser
import DBXCResultParserTestHelpers

class CoverageDTOTests: XCTestCase {
    
    override func setUpWithError() throws {
        try super.setUpWithError()
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
    }
    
    func test_coverageDtoParse() throws {
        XCTAssertNoThrow(try Array<CoverageDTO>(from: Constants.testsReportPath))
    }
    
    func test_coverageDtoData() throws {
        let result = try Array<CoverageDTO>(from: Constants.testsReportPath)
        XCTAssertEqual(result.count, 3) // as targets count
        let expectedResult = CoverageDTO.testMake(
            coveredLines: 299,
            executableLines: 582,
            lineCoverage: 0.5137457044673539,
            name: "DBXCResultParser"
        )
        
        let target = try XCTUnwrap(result.first { $0.name == expectedResult.name })
        
        XCTAssertEqual(target.coveredLines, expectedResult.coveredLines)
        XCTAssertEqual(target.executableLines, expectedResult.executableLines)
        XCTAssertEqual(target.lineCoverage, expectedResult.lineCoverage)
    }
}
