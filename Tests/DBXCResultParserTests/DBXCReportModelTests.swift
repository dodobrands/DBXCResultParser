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
        XCTAssertEqual(module.coverage?.coveredLines, 481)
        
        let files = module.files.sorted { $0.name < $1.name }
        XCTAssertEqual(files.count, 5)
        
        let file = try XCTUnwrap(files.first { $0.name == "DBXCReportModelTests" })
        XCTAssertEqual(file.repeatableTests.count, 6)
        
        let successTest = try XCTUnwrap(file.repeatableTests.first { $0.name == "test_success()" })
        XCTAssertNil(successTest.tests.first?.message)
        
        let failedTest = try XCTUnwrap(file.repeatableTests.first { $0.name == "test_failure()" })
        XCTAssertEqual(failedTest.tests.first?.message, "failed - Failure message")
        
        let skippedTest = try XCTUnwrap(file.repeatableTests.first { $0.name == "test_skip()" })
        XCTAssertEqual(skippedTest.tests.first?.message, "Test skipped - Skip message")
        
        let expectedFailedTest = try XCTUnwrap(file.repeatableTests.first { $0.name == "test_expectedFailure()" })
        XCTAssertEqual(expectedFailedTest.tests.first?.message, "XCTAssertEqual failed: (\"1\") is not equal to (\"2\")")
        
        let flackyTest = try XCTUnwrap(file.repeatableTests.first { $0.name == "test_flacky()" })
        XCTAssertEqual(flackyTest.tests.count, 2)
        XCTAssertEqual(flackyTest.tests.first?.status, .failure)
        XCTAssertEqual(flackyTest.tests.last?.status, .success)
        XCTAssertEqual(flackyTest.combinedStatus, .mixed)
    }
    
//    func test_success() {
//        XCTAssertTrue(true)
//    }
//    
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
//    
//    static var shouldFail = true
//    func test_flacky() {
//        if Self.shouldFail {
//            XCTFail("Flacky failure message")
//        }
//        
//        Self.shouldFail = false
//    }
}
