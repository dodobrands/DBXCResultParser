import XCTest
@testable import TestReportParser

final class ReportFormatterTests: XCTestCase {
    func test_filter_any_list() {
        let result = ReportFormatter.format(report, format: .list)
        
        XCTAssertEqual(result,
                       """
AuthSpec
✅ login
❌ logout
⚠️ openSettings

CaptchaSpec
❌ Another Handle Request
❌ Handle Request

NetworkSpec
✅ MakeRequest

NotificationsSetupServiceTests
⏭ enabledNotifications
""")
    }
    
    func test_filter_success_list() {
        let result = ReportFormatter.format(report, filters: [.succeeded], format: .list)
        XCTAssertEqual(result,
                       """
AuthSpec
✅ login

NetworkSpec
✅ MakeRequest
""")
    }
    
    func test_filter_any_count() {
        let result = ReportFormatter.format(report, format: .count)
        XCTAssertEqual(result, "7")
    }
    
    func test_filter_failure_count() {
        let result = ReportFormatter.format(report, filters: [.failed], format: .count)
        XCTAssertEqual(result, "3")
    }
}

extension ReportFormatterTests {
    var report: ReportModel {
        let profileModule = ReportModel.Module.testMake(
            name: "Profile",
            files: [
                .testMake(
                    name: "AuthSpec",
                    repeatableTests: [
                        .failed(named: "logout"),
                        .succeeded(named: "login"),
                        .mixedFailedSucceeded(named: "openSettings")
                    ]
                )
            ]
        )
        
        let networkModule = ReportModel.Module.testMake(
            name: "Network",
            files: [
                .testMake(
                    name: "NetworkSpec",
                    repeatableTests: [
                        .succeeded(named: "MakeRequest")
                    ]
                ),
                .testMake(
                    name: "CaptchaSpec",
                    repeatableTests: [
                        .failed(named: "Handle Request", times: 2),
                        .failed(named: "Another Handle Request", times: 2)
                    ]
                )
            ]
        )
        let notificationsModule = ReportModel.Module.testMake(
            name: "Notifications",
            files: [
                .testMake(
                    name: "NotificationsSetupServiceTests",
                    repeatableTests: [
                        .skipped(named: "enabledNotifications")
                    ]
                )
            ]
        )
        
        return .testMake(
            modules: [
                profileModule,
                networkModule,
                notificationsModule
            ]
        )
    }
}

extension ReportModel {
    static func testMake(modules: Set<Module> = []) -> Self {
        .init(modules: modules)
    }
}

extension ReportModel.Module {
    static func testMake(name: String = "", files: Set<File> = []) -> Self {
        .init(name: name, files: files)
    }
}

extension ReportModel.Module.File {
    static func testMake(name: String = "", repeatableTests: Set<RepeatableTest> = []) -> Self {
        .init(name: name, repeatableTests: repeatableTests)
    }
}

extension ReportModel.Module.File.RepeatableTest {
    static func testMake(name: String = "", tests: [Test] = []) -> Self {
        .init(name: name, tests: tests)
    }
    
    static func failed(named name: String, times: Int = 1) -> Self {
        let tests = Array(
            repeating: ReportModel.Module.File.RepeatableTest.Test.testMake(status: .failure),
            count: times
        )
        return .testMake(name: name, tests: tests)
    }
    
    static func succeeded(named name: String) -> Self {
        .testMake(name: name, tests: [.testMake(status: .success)])
    }
    
    static func skipped(named name: String) -> Self {
        .testMake(name: name, tests: [.testMake(status: .skipped)])
    }
    
    static func mixedFailedSucceeded(named name: String, failedTimes: Int = 1) -> Self {
        let failedTests = Array(
            repeating: ReportModel.Module.File.RepeatableTest.Test.testMake(status: .failure),
            count: failedTimes
        )
        return .testMake(name: name, tests: failedTests + [.testMake(status: .success)])
    }
}

extension ReportModel.Module.File.RepeatableTest.Test {
    static func testMake(status: Status = .success,
                         duration: Double = 0) -> Self {
        .init(status: status, duration: duration)
    }
}
