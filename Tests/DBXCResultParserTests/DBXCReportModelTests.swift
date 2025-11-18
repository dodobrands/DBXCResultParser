// Created by Yaroslav Bredikhin on 06.09.2022

import Foundation
import Testing

@testable import DBXCResultParser

@Suite
struct DBXCReportModelTests {

    @Test
    func test() throws {
        let report = try DBXCReportModel(xcresultPath: Constants.testsReportPath)
        #expect(report.modules.count == 2)

        let module = try #require(
            report.modules.first(where: { $0.name == "DBXCResultParserTests" }))
        #expect(module.coverage?.coveredLines == 481)

        let files = module.files.sorted { $0.name < $1.name }
        #expect(files.count == 5)

        let file = try #require(files.first(where: { $0.name == "DBXCReportModelTests" }))
        #expect(file.repeatableTests.count == 6)

        let successTest = try #require(
            file.repeatableTests.first(where: { $0.name == "test_success()" }))
        #expect(successTest.tests.first?.message == nil)

        let failedTest = try #require(
            file.repeatableTests.first(where: { $0.name == "test_failure()" }))
        #expect(failedTest.tests.first?.message == "failed - Failure message")

        let skippedTest = try #require(
            file.repeatableTests.first(where: { $0.name == "test_skip()" }))
        #expect(skippedTest.tests.first?.message == "Test skipped - Skip message")

        let expectedFailedTest = try #require(
            file.repeatableTests.first(where: { $0.name == "test_expectedFailure()" }))
        #expect(
            expectedFailedTest.tests.first?.message
                == "XCTAssertEqual failed: (\"1\") is not equal to (\"2\")")

        let flackyTest = try #require(
            file.repeatableTests.first(where: { $0.name == "test_flacky()" }))
        #expect(flackyTest.tests.count == 2)
        #expect(flackyTest.tests.first?.status == .failure)
        #expect(flackyTest.tests.last?.status == .success)
        #expect(flackyTest.combinedStatus == .mixed)
    }

    //    @Test
    //    func test_success() {
    //        #expect(true)
    //    }
    //
    //    @Test
    //    func test_failure() {
    //        Issue.record("Failure message")
    //    }
    //
    //    @Test
    //    func test_skip() throws {
    //        throw Test.Skipped("Skip message")
    //    }
    //
    //    @Test
    //    func test_expectedFailure() {
    //        // Note: Swift Testing doesn't have XCTExpectFailure equivalent
    //        // This test would need to be adapted based on requirements
    //        #expect(1 == 2)
    //    }
    //
    //    static var shouldFail = true
    //    @Test
    //    func test_flacky() {
    //        if Self.shouldFail {
    //            Issue.record("Flacky failure message")
    //        }
    //
    //        Self.shouldFail = false
    //    }
}
