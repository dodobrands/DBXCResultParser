import XCTest
@testable import TestParser

final class TestParserTests: XCTestCase {

    func testExample() throws {
        let reportPath = try XCTUnwrap(Bundle.module.url(forResource: "report", withExtension: "json"))

        let report = try ReportParser(filePath: reportPath).unitTestsReport
        
        let failedName1 = "AuthorizationTests.test_guest_can_login_in_russia_with_lithuania_phone()"
        let failedName2 = "AuthorizationTests.test_guest_can_login_in_russia_with_estonia_phone()"

        XCTAssertEqual(report.actions._values[0].actionResult.issues.testFailureSummaries?._values[0].testCaseName._value,
                       failedName1)
        XCTAssertEqual(report.actions._values[0].actionResult.issues.testFailureSummaries?._values[1].testCaseName._value,
                       failedName2)

        XCTAssertEqual(try report.failedNames(),
                       [failedName1, failedName2])
    }
    
    func testExample2() throws {
        let reportPath = try XCTUnwrap(Bundle.module.url(forResource: "reportUnitsFailure", withExtension: "json"))
        let report = try ReportParser(filePath: reportPath).unitTestsReport
        
        let failedName = "DownloadImageServiceSpec.DownloadImageService__prefetchFirstSmallImagesForAllCategories__when_not_2G__it_should_prefetch()"
        
        XCTAssertEqual(report.actions._values[0].actionResult.issues.testFailureSummaries?._values[0].testCaseName._value,
                       failedName)
        XCTAssertEqual(try report.failedNames(),
                       [failedName])
    }
}

