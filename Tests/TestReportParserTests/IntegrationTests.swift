import XCTest
@testable import TestReportParser

final class IntegrationTests: XCTestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
    }
    
    func test_parse_failed_list () throws {
        let result = try Parser(xcresultPath: Constants.unitTestsReportPath).parse(filters: [.failed], format: .list)
        let expectedResult = """
CartHeaderCellSpec
❌ CartHeaderCell__regular_state_with_delivery_amount__should_snapshot()
❌ CartHeaderCell__regular_state_with_delivery_amount__when_translation_is_very_long__should_fit()
❌ CartHeaderCell__simple_state__should_snapshot()
"""
        XCTAssertEqual(String(result.prefix(expectedResult.count)), expectedResult)
    }
    
    func test_parse_failed_count() throws {
        let result = try Parser(xcresultPath: Constants.unitTestsReportPath).parse(filters: [.failed], format: .count)
        XCTAssertEqual(result, "77")
    }

    func test_parse_any_count() throws {
        let result = try Parser(xcresultPath: Constants.unitTestsReportPath).parse(format: .count)
        XCTAssertEqual(result, "3708")
    }

    func test_parse_skipped_count() throws {
        let result = try Parser(xcresultPath: Constants.unitTestsReportPath).parse(filters: [.skipped], format: .count)
        XCTAssertEqual(result, "3")
    }
    
    func test_parse_skipped_list() throws {
        let result = try Parser(xcresultPath: Constants.unitTestsReportPath).parse(filters: [.skipped], format: .list)
        XCTAssertEqual(result, """
StateSaveServiceTests
⏭ test_whenAutoPromocodeIsAppliedForRestaurant_thenShouldShowNotification()
⏭ test_when_actualize_realRestApp_isON_and_receivedOrderType_carryout_should_resetState()
⏭ test_when_save_realRestApp_isON_and_receivedOrderType_carryout_should_resetState()
""")
    }

    func test_parse_mixed_list() throws {
        let result = try Parser(xcresultPath: Constants.e2eTestsReportPath).parse(filters: [.mixed], format: .list)
        XCTAssertEqual(result,
        """
DeepLinksTests
⚠️ test_promocode_is_invalid_deeplink()
""")
    }
    
    func test_parse_slow_list() throws {
        let slowThreshold = Measurement<UnitDuration>(value: 100, unit: .milliseconds)
        let result = try Parser(xcresultPath: Constants.unitTestsReportPath).parse(filters: [.slow(duration: slowThreshold)], format: .list)
        let expectedResult = """
AlertViewSpec
✅🕢 [449 ms] EmailSubscriptionCell__snapshot()

AnalyticsAuthorizationServiceSpec
✅🕢 [313 ms] AnalyticsAuthorizationServiceSpec__when_logged__should_send_event_to_mindbox()
"""

        XCTAssertEqual(
            String(result.prefix(expectedResult.count)),
            expectedResult
        )
    }
    
    func test_parse_failedMixed_list() throws {
        let result = try Parser(xcresultPath: Constants.e2eTestsReportPath).parse(filters: [.failed, .mixed], format: .list)
        XCTAssertEqual(result,
        """
DeepLinksTests
❌ test_open_order_by_deeplink()
❌ test_pizza_halves_screen_deeplink()
⚠️ test_promocode_is_invalid_deeplink()
""")
    }
}
