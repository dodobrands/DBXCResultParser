import Foundation
import Testing

@testable import DBXCResultParser

struct DBXCReportModelActualTests {

    @Test
    func test_xcresultFilesCount() throws {
        let reportPaths = try Constants.testsReportPaths
        #expect(!reportPaths.isEmpty)
    }

    @Test
    func test() async throws {
        let reportPaths = try Constants.testsReportPaths
        #expect(!reportPaths.isEmpty)

        // Parse all available xcresult files
        for reportPath in reportPaths {
            let report = try await DBXCReportModel(xcresultPath: reportPath)
            let fileName = reportPath.lastPathComponent
            let expected = try Constants.expectedReportValues(for: fileName)

            // Basic validation for all files
            #expect(!report.modules.isEmpty)

            // Detailed validation for all files
            #expect(report.modules.count == expected.modulesCount)

            let module = try #require(
                report.modules.first(where: { $0.name == "DBXCResultParserTests" }))
            #expect(module.coverage?.coveredLines == expected.coverageLines)

            let files = module.files.sorted { $0.name < $1.name }
            #expect(files.count == expected.filesCount)

            let file = try #require(files.first(where: { $0.name == "DBXCReportModelTests" }))
            #expect(file.repeatableTests.count == expected.repeatableTestsCount)

            let successTest = try #require(
                file.repeatableTests.first(where: { $0.name == "test_success()" }))
            #expect(successTest.tests.first?.message == nil)

            let failedTest = try #require(
                file.repeatableTests.first(where: { $0.name == "test_failure()" }))
            #expect(failedTest.tests.first?.message == "Failure message")

            let skippedTest = try #require(
                file.repeatableTests.first(where: { $0.name == "test_skip()" }))
            #expect(skippedTest.tests.first?.message == "Skip message")

            let expectedFailedTest = try #require(
                file.repeatableTests.first(where: { $0.name == "test_expectedFailure()" }))
            // expectedFailure tests show "Failure is expected" instead of detailed message
            #expect(
                expectedFailedTest.tests.first?.message == "Failure is expected")

            let flackyTest = try #require(
                file.repeatableTests.first(where: { $0.name == "test_flacky()" }))
            #expect(flackyTest.tests.count == expected.flackyTestsCount)
            #expect(flackyTest.tests.first?.status == .failure)
            if expected.flackyTestsCount > 1 {
                #expect(flackyTest.tests.last?.status == .success)
                #expect(flackyTest.combinedStatus == .mixed)
            } else {
                #expect(flackyTest.combinedStatus == .failure)
            }
        }
    }
}

// XCODE_VERSION=$(xcodebuild -version | head -1 | awk '{print $2}') && xcodebuild test -scheme DBXCResultParser-Package -destination 'platform=macOS' -enableCodeCoverage YES -retry-tests-on-failure -test-iterations 3 -collect-test-diagnostics never -enablePerformanceTestsDiagnostics NO -resultBundlePath "Tests/DBXCResultParserTests/Resources/DBXCResultParser-${XCODE_VERSION}.xcresult"
//
// Flow:
// 1) uncomment the tests below
// 2) run tests via command - a new file will be created for the new Xcode version
// 3) run tests via Xcode - it will show errors because the new file is now included in tests
// 4) update existing tests to include data for new xcresult files so tests become green
//
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
