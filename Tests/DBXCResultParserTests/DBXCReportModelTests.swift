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
        XCTAssertEqual(report.modules.count, 2)
        
        let module = try XCTUnwrap(report.modules.first { $0.name == "DBXCResultParserTests" })
        XCTAssertEqual(module.coverage?.coveredLines, 477)
        
        let files = module.files.sorted { $0.name < $1.name }
        XCTAssertEqual(files.count, 5)
        
        let file = try XCTUnwrap(files.first { $0.name == "DBXCReportModelTests" })
        XCTAssertEqual(file.repeatableTests.count, 4)
        
        let successTest = try XCTUnwrap(file.repeatableTests.first { $0.name == "test()" })
        let failedTest = try XCTUnwrap(file.repeatableTests.first { $0.name == "test_failure()" })
        let skippedTest = try XCTUnwrap(file.repeatableTests.first { $0.name == "test_skip()" })
        let expectedFailedTest = try XCTUnwrap(file.repeatableTests.first { $0.name == "test_expectedFailure()" })
        
        XCTAssertEqual(failedTest.tests.first?.message, "failed - Failure message")
        XCTAssertEqual(skippedTest.tests.first?.message, "Test skipped - Skip message")
        XCTAssertEqual(expectedFailedTest.tests.first?.message, "XCTAssertEqual failed: (\"1\") is not equal to (\"2\")")
        XCTAssertNil(successTest.tests.first?.message)
    }
    
//    func test_failure() {
//        XCTFail("Failure message")
//    }
//    
//    func test_skip() throws {
//        throw XCTSkip("Skip message")
//    }
//    
//    func test_expectedFailure() {
//        XCTExpectFailure("Failure is expected")
//        XCTAssertEqual(1, 2)
//    }
}
