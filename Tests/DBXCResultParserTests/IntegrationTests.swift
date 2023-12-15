import XCTest
@testable import DBXCResultParser

final class IntegrationTests: XCTestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()
        Formatter.locale = Locale(identifier: "en-US")
    }
    
    override func tearDownWithError() throws {
        Formatter.locale = nil
        try super.tearDownWithError()
    }
    
    func test_parse_failed_list () throws {
        let result = try Parser(xcresultPath: Constants.unitTestsReportPath).parse(filters: [.failed], format: .text(format: .list))
        let expectedResult = """
        CartHeaderCellSpec
        ❌ CartHeaderCell__regular_state_with_delivery_amount__should_snapshot()
        ❌ CartHeaderCell__regular_state_with_delivery_amount__when_translation_is_very_long__should_fit()
        ❌ CartHeaderCell__simple_state__should_snapshot()
        """
        XCTAssertEqual(String(result.prefix(expectedResult.count)), expectedResult)
    }
    
    func test_parse_slow_3s_list () throws {
        let result = try Parser(xcresultPath: Constants.unitTestsReportPath).parse(filters: [.slow(duration: .init(value: 3, unit: .seconds))], format: .text(format: .list))
        let expectedResult = """
        ContactsViewControllerSpec
        ✅🕢 (3 sec) ContactsViewController__load_view__when_feedback_block_are_visible__when_chat_enabled__should_snapshot()
        ✅🕢 (3 sec) ContactsViewController__load_view__when_location_button_is_visible__should_snapshot()
        """
        XCTAssertEqual(String(result.prefix(expectedResult.count)), expectedResult)
    }
    
    func test_parse_slow_3s_count() throws {
        let result = try Parser(xcresultPath: Constants.unitTestsReportPath).parse(filters: [.slow(duration: .init(value: 3, unit: .seconds))], format: .text(format: .count))
        XCTAssertEqual(result, "2 (7 sec)")
    }
    
    func test_parse_failed_count() throws {
        let result = try Parser(xcresultPath: Constants.unitTestsReportPath).parse(filters: [.failed], format: .text(format: .count))
        XCTAssertEqual(result, "77 (9 sec)")
    }
    
    func test_parse_failed_slow_3s_count() throws {
        let result = try Parser(xcresultPath: Constants.unitTestsReportPath).parse(filters: [.failed, .slow(duration: .init(value: 3, unit: .seconds))], format: .text(format: .count))
        XCTAssertEqual(result, "79 (16 sec)")
    }

    func test_parse_any_count() throws {
        let result = try Parser(xcresultPath: Constants.unitTestsReportPath).parse(format: .text(format: .count))
        XCTAssertEqual(result, "3708 (2 min)")
    }

    func test_parse_skipped_count() throws {
        let result = try Parser(xcresultPath: Constants.unitTestsReportPath).parse(filters: [.skipped], format: .text(format: .count))
        XCTAssertEqual(result, "3")
    }
    
    func test_parse_skipped_list() throws {
        let result = try Parser(xcresultPath: Constants.unitTestsReportPath).parse(filters: [.skipped], format: .text(format: .list))
        XCTAssertEqual(result, """
        StateSaveServiceTests
        ⏭ test_whenAutoPromocodeIsAppliedForRestaurant_thenShouldShowNotification()
        ⏭ test_when_actualize_realRestApp_isON_and_receivedOrderType_carryout_should_resetState()
        ⏭ test_when_save_realRestApp_isON_and_receivedOrderType_carryout_should_resetState()
        """)
    }

    func test_parse_mixed_list() throws {
        let result = try Parser(xcresultPath: Constants.e2eTestsReportPath).parse(filters: [.mixed], format: .text(format: .list))
        XCTAssertEqual(result, """
        DeepLinksTests
        ⚠️ test_promocode_is_invalid_deeplink()
        """)
    }
    
    func test_parse_slow_list() throws {
        let slowThreshold = Duration(value: 100, unit: .milliseconds)
        let result = try Parser(xcresultPath: Constants.unitTestsReportPath).parse(filters: [.slow(duration: slowThreshold)], format: .text(format: .list))
        let expectedResult = """
        AlertViewSpec
        ✅🕢 (449 ms) EmailSubscriptionCell__snapshot()

        AnalyticsAuthorizationServiceSpec
        ✅🕢 (313 ms) AnalyticsAuthorizationServiceSpec__when_logged__should_send_event_to_mindbox()
        """

        XCTAssertEqual(
            String(result.prefix(expectedResult.count)),
            expectedResult
        )
    }
    
    func test_parse_failedMixed_list() throws {
        let result = try Parser(xcresultPath: Constants.e2eTestsReportPath).parse(filters: [.failed, .mixed], format: .text(format: .list))
        XCTAssertEqual(result, """
        DeepLinksTests
        ❌ test_open_order_by_deeplink()
        ❌ test_pizza_halves_screen_deeplink()
        ⚠️ test_promocode_is_invalid_deeplink()
        """)
    }
    
    func test_parse_warning_count() throws {
        let parser = try Parser(xcresultPath: Constants.unitTestsWithCoverageReportPath)
        XCTAssertEqual(parser.report.warningCount, 325)
    }
    
    func test_parse_coverage() throws {
        let parser = try Parser(xcresultPath: Constants.unitTestsWithCoverageReportPath)
        for module in parser.report.modules {
            XCTAssertNotNil(module.coverage)
        }
    }
    
    func test_parse_coverage_model() throws {
        let parser = try Parser(xcresultPath: Constants.unitTestsWithCoverageReportPath)
        let missionsModuleCoverage = parser.report.modules.first { $0.name == "MissionsTests" }?.coverage
        XCTAssertNotNil(missionsModuleCoverage)
        XCTAssertEqual(missionsModuleCoverage, .testMake(name: "Missions.framework",
                                                         coveredLines: 843,
                                                         totalLines: 1964,
                                                         coverage: 0.42922606924643586))
    }
    
    func test_total_coverage() throws {
        let parser = try Parser(xcresultPath: Constants.unitTestsWithCoverageReportPath)
        XCTAssertEqual(parser.report.totalCoverage!, 0.4164, accuracy: 0.0001)
    }
    
    func test_totalCoverage_whenZeroModules_shouldReturnNil() {
        let report = ReportModel(modules: [])
        XCTAssertNil(report.totalCoverage)
    }
    
    func test_totalCoverage_whenOneModule_shouldReturnTheModulesCoverage() {
        let moduleWithCoverage: ReportModel.Module = .testMake(coverage: .testMake(coveredLines: 456,
                                                                                   totalLines: 789,
                                                                                   coverage: 0.234))
        let report = ReportModel(modules: [moduleWithCoverage])
        XCTAssertEqual(report.totalCoverage!, 0.5779, accuracy: 0.0001)
    }
    
    func test_totalCoverage_shouldReturnModulesAvgCoverage() {
        let moduleWithCoverage1: ReportModel.Module = .testMake(name: "1",
                                                                coverage: .testMake(coveredLines: 1,
                                                                                    totalLines: 2))
        let moduleWithCoverage2: ReportModel.Module = .testMake(name: "2",
                                                                coverage: .testMake(coveredLines: 19,
                                                                                    totalLines: 20))
        let report = ReportModel(modules: [moduleWithCoverage1, moduleWithCoverage2])
        XCTAssertEqual(report.totalCoverage!, 0.9, accuracy: 0.01)
    }
}

