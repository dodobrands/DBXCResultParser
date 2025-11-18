import Foundation
import Testing

@testable import DBXCResultParser

//extension Tag {
//    @Tag static var xcresultGeneration: Self
//}
//
//@Suite
//struct DBXCReportModelTests {
//
//    // Set to true to enable xcresult generation tests.
//    // These tests are used to generate .xcresult file with a new Xcode version.
//    //
//    // To run only these tests: in Xcode's test navigator, go to the Tags section and click Run next to the xcresultGeneration tag.
//    //
//    // Originally planned to create a script that would run tests with xcresultGeneration tag via swift test
//    // and automatically generate .xcresult file with correct name (including Xcode version) in the right location,
//    // but ran into limitation: swift test doesn't support filtering by tags (at least in Xcode 26).
//    //
//    // Therefore, tests are controlled by this constant instead of using the tag for filtering,
//    // and finding the generated .xcresult file, moving it to the right location, and renaming are done manually.
//    let generateXcresult = false
//
//    @Test(.tags(.xcresultGeneration))
//    func test_success() throws {
//        guard generateXcresult else {
//            return  // Skip test if constant is not enabled
//        }
//        #expect(true)
//    }
//
//    @Test(.tags(.xcresultGeneration))
//    func test_failure() throws {
//        guard generateXcresult else {
//            return
//        }
//        Issue.record("Failure message")
//    }
//
//    @Test(.tags(.xcresultGeneration), .disabled("Skip message"))
//    func test_skip() throws {
//        guard generateXcresult else {
//            return
//        }
//
//        return
//    }
//
//    @Test(.tags(.xcresultGeneration))
//    func test_expectedFailure() throws {
//        guard generateXcresult else {
//            return
//        }
//        withKnownIssue {
//            #expect(1 == 2)
//        }
//    }
//
//    nonisolated(unsafe) static var shouldFail = true
//    @Test(.tags(.xcresultGeneration))
//    func test_flacky() throws {
//        guard generateXcresult else {
//            return
//        }
//        if Self.shouldFail {
//            Issue.record("Flacky failure message")
//        }
//
//        Self.shouldFail = false
//    }
//}

struct DBXCReportModelActualTests {

    @Test
    func test() async throws {
        let report = try await DBXCReportModel(xcresultPath: Constants.testsReportPath)
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
        // In new format, expectedFailure tests show "Failure is expected" instead of detailed message
        #expect(
            expectedFailedTest.tests.first?.message == "Failure is expected")

        let flackyTest = try #require(
            file.repeatableTests.first(where: { $0.name == "test_flacky()" }))
        #expect(flackyTest.tests.count == 2)
        #expect(flackyTest.tests.first?.status == .failure)
        #expect(flackyTest.tests.last?.status == .success)
        #expect(flackyTest.combinedStatus == .mixed)
    }
}
//
//import XCTest
//class DBXCReportModelTests: XCTestCase {
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
//    static nonisolated(unsafe) var shouldFail = true
//    func test_flacky() {
//        if Self.shouldFail {
//            XCTFail("Flacky failure message")
//        }
//
//        Self.shouldFail = false
//    }
//}
