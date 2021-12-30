import XCTest
@testable import TestParser

final class TestParserTests: XCTestCase {

    func testExample() throws {
        let reportPath = try XCTUnwrap(Bundle.module.url(forResource: "report", withExtension: "json"))
        let parser = JSONFileParser(filePath: reportPath)

        let report: Report = try parser.parse()

        XCTAssertEqual(report.actions._values[0].actionResult.issues.testFailureSummaries?._values[0].testCaseName._value,
                       "AuthorizationTests.test_guest_can_login_in_russia_with_lithuania_phone()")
        XCTAssertEqual(report.actions._values[0].actionResult.issues.testFailureSummaries?._values[1].testCaseName._value,
                       "AuthorizationTests.test_guest_can_login_in_russia_with_estonia_phone()")

        let names = ["AuthorizationTests.test_guest_can_login_in_russia_with_lithuania_phone()",
                     "AuthorizationTests.test_guest_can_login_in_russia_with_estonia_phone()"]
        
        let newReport: Report = try parser.parse()
        XCTAssertEqual(try newReport.failedNames(),
                       names)
    }
    
    func testExample2() throws {
        let reportPath = try XCTUnwrap(Bundle.module.url(forResource: "reportUnitsFailure", withExtension: "json"))
        let parser = JSONFileParser(filePath: reportPath)
        
        let report: Report = try parser.parse()
        
        XCTAssertEqual(report.actions._values[0].actionResult.issues.testFailureSummaries?._values[0].testCaseName._value,
                       "DownloadImageServiceSpec.DownloadImageService__prefetchFirstSmallImagesForAllCategories__when_not_2G__it_should_prefetch()")
        
        let names = ["DownloadImageServiceSpec.DownloadImageService__prefetchFirstSmallImagesForAllCategories__when_not_2G__it_should_prefetch()"]
        let newReport: Report = try parser.parse()
        XCTAssertEqual(try newReport.failedNames(),
                       names)
    }
}
    



//class XCResultParserTests: XCTestCase {
//    func testExample2() throws {
//
//        var shellOutput: String? = nil
//        let sut = XCResultParser(filePath: URL(string: "output/E2E.xcresult")!) { command in
//            shellOutput = command
//        }
//
//        let reportPath = try sut.parse()
//
//        XCTAssertEqual(reportPath, URL(string: "output/report.json"))
//        XCTAssertEqual(shellOutput, "xcrun xcresulttool get --path output/E2E.xcresult --format json > report.json")
//    }
//}


