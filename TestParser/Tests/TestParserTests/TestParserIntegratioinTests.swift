import XCTest
@testable import TestParser

final class TestParserIntegratioinTests: XCTestCase {
    
    func testParseList() throws {
        let reportPath = try XCTUnwrap(Bundle.module.url(forResource: "reportUnitsFailure", withExtension: "json"))
        let report = try ReportParser(filePath: reportPath).parseList()
        XCTAssertEqual("\(report)",
                       """
DownloadImageServiceSpec:
❌ DownloadImageService__prefetchFirstSmallImagesForAllCategories__when_not_2G__it_should_prefetch()
""")
    }

    func testParseTotal() throws {
        let reportPath = try XCTUnwrap(Bundle.module.url(forResource: "reportUnitsWithoutErrors", withExtension: "json"))
        let report = try ReportParser(filePath: reportPath).parseTotalTests()
        XCTAssertEqual("\(report)","3350")
    }

    func testParseFailedTests() throws {
        let reportPath = try XCTUnwrap(Bundle.module.url(forResource: "reportUnitsFailure", withExtension: "json"))
        let report = try ReportParser(filePath: reportPath).parseFailedTests()
        XCTAssertEqual("\(report)","1")
    }

    func testParseSkippedTests() throws {
        let reportPath = try XCTUnwrap(Bundle.module.url(forResource: "reportUnitsFailure", withExtension: "json"))
        let report = try ReportParser(filePath: reportPath).parseSkippedTests()
        XCTAssertEqual("\(report)","3")
    }
}
