import XCTest
@testable import TestParser

final class ReportFormatterTests: XCTestCase {
    func test_filter_any_list() {
        let result = ReportFormatter.format(report, filter: .any, format: .list)
        
        XCTAssertEqual(result,
                       """
AuthSpec
⏭ enabledNotifications
✅ login
❌ logout
⚠️ openSettings

CaptchaSpec
❌ Another Handle Request
❌ Handle Request

NetworkSpec
✅ MakeRequest
""")
    }
    
    func test_filter_success_list() {
        let result = ReportFormatter.format(report, filter: .succeeded, format: .list)
        XCTAssertEqual(result,
                       """
AuthSpec
✅ login

NetworkSpec
✅ MakeRequest
""")
    }
    
    func test_filter_any_count() {
        let result = ReportFormatter.format(report, filter: .any, format: .count)
        XCTAssertEqual(result, "7")
    }
    
    func test_filter_failure_count() {
        let result = ReportFormatter.format(report, filter: .failed, format: .count)
        XCTAssertEqual(result, "3")
    }
}

extension ReportFormatterTests {
    var report: ReportModel {
        ReportModel(
            files: [
                .init(
                    name: "AuthSpec",
                    repeatableTests: [
                        .init(
                            name: "logout",
                            tests: [
                                .init(
                                    status: .failure,
                                    duration: 0.1
                                )
                            ]
                        ),
                        .init(
                            name: "login",
                            tests: [
                                .init(
                                    status: .success,
                                    duration: 0.1
                                )
                            ]
                        ),
                        .init(
                            name: "openSettings",
                            tests: [
                                .init(
                                    status: .failure,
                                    duration: 0.1
                                ),
                                .init(
                                    status: .success,
                                    duration: 0.1
                                )
                            ]
                        ),
                        .init(
                            name: "enabledNotifications",
                            tests: [
                                .init(
                                    status: .skipped,
                                    duration: 0.1
                                )
                            ]
                        )
                    ]
                ),
                .init(
                    name: "NetworkSpec",
                    repeatableTests: [
                        .init(
                            name: "MakeRequest",
                            tests: [
                                .init(
                                    status: .success,
                                    duration: 1
                                )
                            ]
                        )
                    ]
                ),
                .init(
                    name: "CaptchaSpec",
                    repeatableTests: [
                        .init(
                            name: "Handle Request",
                            tests: [
                                .init(
                                    status: .failure,
                                    duration: 1
                                ),
                                .init(
                                    status: .failure,
                                    duration: 1
                                )
                            ]
                        ),
                        .init(
                            name: "Another Handle Request",
                            tests: [
                                .init(
                                    status: .failure,
                                    duration: 1
                                ),
                                .init(
                                    status: .failure,
                                    duration: 1
                                )
                            ]
                        )
                    ]
                )
            ]
        )
    }
}
