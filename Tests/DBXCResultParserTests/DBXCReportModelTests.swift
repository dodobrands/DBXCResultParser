// Created by Yaroslav Bredikhin on 06.09.2022

import Foundation
import XCTest
@testable import DBXCResultParser

class DBXCReportModelTests: XCTestCase {
    
    override func setUpWithError() throws {
        try super.setUpWithError()
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
    }
    
    func test() throws {
        let report = try DBXCReportModel(xcresultPath: Constants.testsReportPath)
        XCTAssertEqual(report.modules.count, 1)
        
        let module = try XCTUnwrap(report.modules.first)
        XCTAssertEqual(module.name, "DBXCResultParserTests")
        XCTAssertEqual(module.coverage?.coveredLines, 299)
        
        let files = module.files.sorted { $0.name < $1.name }
        XCTAssertEqual(files.count, 5)
        
        let file = try XCTUnwrap(files.first)
        XCTAssertEqual(file.name, "CoverageDTOTests")
        XCTAssertEqual(file.repeatableTests.count, 1)
        
        let test = try XCTUnwrap(file.repeatableTests.first)
        XCTAssertEqual(test.name, "test_file_with_coverage()")
    }
}
