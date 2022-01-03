import XCTest
@testable import TestParser

final class TestParserIntegratioinTests: XCTestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
    }
    
    func test_parse_failed_list () throws {
        let result = try ReportParser(xcresultPath: TestsConstants.unitTestsReportPath).parse(filter: .failed, format: .list)
        XCTAssertTrue(result.hasPrefix(
                       """
CartHeaderCellSpec
❌ CartHeaderCell__regular_state_with_delivery_amount__should_snapshot()
❌ CartHeaderCell__regular_state_with_delivery_amount__when_translation_is_very_long__should_fit()
❌ CartHeaderCell__simple_state__should_snapshot()
"""
                                      )
        )
    }
    
    func test_parse_failed_count() throws {
        let result = try ReportParser(xcresultPath: TestsConstants.unitTestsReportPath).parse(filter: .failed, format: .count)
        XCTAssertEqual(result, "77")
    }

    func test_parse_any_count() throws {
        let result = try ReportParser(xcresultPath: TestsConstants.unitTestsReportPath).parse(filter: .any, format: .count)
        XCTAssertEqual(result, "3708")
    }

    func test_parse_skipped_count() throws {
        let result = try ReportParser(xcresultPath: TestsConstants.unitTestsReportPath).parse(filter: .skipped, format: .count)
        XCTAssertEqual(result, "3")
    }

    func test_parse_mixed_list() throws {
        let result = try ReportParser(xcresultPath: TestsConstants.e2eTestsReportPath).parse(filter: .mixed, format: .list)
        XCTAssertEqual(result,
        """
DeepLinksTests
⚠️ test_promocode_is_invalid_deeplink()
""")
    }
}
