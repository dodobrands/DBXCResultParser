import XCTest
@testable import TestParser

final class TestParserIntegratioinTests: XCTestCase {
    
    func testParseList() throws {
        let reportPath = try XCTUnwrap(Bundle.module.url(forResource: "reportUnitsFailure", withExtension: "json"))
        let report = try ReportParser(filePath: reportPath).parse(mode: .list)
        XCTAssertEqual("\(report)",
                       """
DownloadImageServiceSpec:
❌ DownloadImageService__prefetchFirstSmallImagesForAllCategories__when_not_2G__it_should_prefetch()
""")
    }

    func testParseTotal() throws {
        let reportPath = try XCTUnwrap(Bundle.module.url(forResource: "reportUnitsWithoutErrors", withExtension: "json"))
        let report = try ReportParser(filePath: reportPath).parse(mode: .total)
        XCTAssertEqual("\(report)","3350")
    }

    func testParseFailedTests() throws {
        let reportPath = try XCTUnwrap(Bundle.module.url(forResource: "reportUnitsFailure", withExtension: "json"))
        let report = try ReportParser(filePath: reportPath).parse(mode: .failed)
        XCTAssertEqual("\(report)","1")
    }

    func testParseSkippedTests() throws {
        let reportPath = try XCTUnwrap(Bundle.module.url(forResource: "reportUnitsFailure", withExtension: "json"))
        let report = try ReportParser(filePath: reportPath).parse(mode: .skipped)
        XCTAssertEqual("\(report)","3")
    }

    func testParseE2EFlaky() throws {
        let reportPath = try XCTUnwrap(Bundle.module.url(forResource: "testsRefFileMixed", withExtension: "json"))
        let report = try ReportParser(filePath: reportPath).parse(mode: .E2EFlaky)
        print(report)
        XCTAssertEqual("\(report)",
        """
CountriesCreateOrderTests:
🟡 test_belarus_create_order()
""")
    }

    func testParseE2EFailed() throws {
        let reportPath = try XCTUnwrap(Bundle.module.url(forResource: "testsRefFileMixed", withExtension: "json"))
        let report = try ReportParser(filePath: reportPath).parse(mode: .E2EFailed)
        print(report)
        XCTAssertEqual("\(report)",
        """
DeepLinksTests:
🔴 test_pizza_halves_deeplink_open_with_terminate()
""")
    }
}
