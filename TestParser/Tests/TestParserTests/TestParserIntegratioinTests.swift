import XCTest
@testable import TestParser

final class TestParserIntegratioinTests: XCTestCase {
    
    func testExample1() throws {
        let reportPath = try XCTUnwrap(Bundle.module.url(forResource: "reportUnitsFailure", withExtension: "json"))
        let report = try ReportParser(filePath: reportPath).parse()
        XCTAssertEqual("\(report)",
                       """
DownloadImageServiceSpec:
❌ DownloadImageService__prefetchFirstSmallImagesForAllCategories__when_not_2G__it_should_prefetch()

Total: 195, failed: 2
""")
    }
}
