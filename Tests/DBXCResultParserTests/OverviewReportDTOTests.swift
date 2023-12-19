//
//  OverviewReportDTOTests.swift
//  
//
//  Created by Алексей Берёзка on 30.12.2021.
//

import Foundation
import XCTest
@testable import DBXCResultParser

class OverviewReportDTOTests: XCTestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
    }
    
    func test() {
        XCTAssertNoThrow(try OverviewReportDTO(from: Constants.testsReportPath))
    }
}
