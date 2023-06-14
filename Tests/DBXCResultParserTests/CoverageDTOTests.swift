// Created by Yaroslav Bredikhin on 06.09.2022

import Foundation
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
    
    func test_file_with_coverage() throws {
        XCTAssertNoThrow(try Array<CoverageDTO>(from: Constants.unitTestsWithCoverageReportPath))
    }
}
