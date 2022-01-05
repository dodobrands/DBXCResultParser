import XCTest
@testable import TestReportParser

final class FormatterTests: XCTestCase {
    func test_filter_any_list() {
        let result = Formatter.format(generalReport, format: .list)
        
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
        let result = Formatter.format(generalReport, filters: [.succeeded], format: .list)
        XCTAssertEqual(result,
                       """
AuthSpec
✅ login

NetworkSpec
✅ MakeRequest
""")
    }
    
    func test_filter_any_count() {
        let result = Formatter.format(generalReport, format: .count)
        XCTAssertEqual(result, "7")
    }
    
    func test_filter_failure_count() {
        let result = Formatter.format(generalReport, filters: [.failed], format: .count)
        XCTAssertEqual(result, "3")
    }
    
    func test_filter_slow_list() {
        // Module with slow tests
        let slowThreshold = Measurement<UnitDuration>(value: 100, unit: .milliseconds)
        let fsModule = ReportModel.Module.testMake(
            name: "FSModule",
            files: [
                .testMake(
                    name: "WriterSpec",
                    repeatableTests: [
                        .testMake(
                            name: "Check folder exists",
                            tests: [
                                .testMake(status: .success, duration: slowThreshold / 2)
                            ]
                        ),
                        .testMake(
                            name: "Check file exists",
                            tests: [
                                .testMake(status: .success, duration: slowThreshold)
                            ]
                        ),
                        .testMake(
                            name: "Read from file",
                            tests: [
                                .testMake(status: .success, duration: slowThreshold * 2)
                            ]
                        ),
                        .testMake(
                            name: "Write to file",
                            tests: [
                                .testMake(status: .failure, duration: slowThreshold / 2),
                                .testMake(status: .success, duration: slowThreshold * 2),
                            ]
                        )
                    ]
                )
            ]
        )
        let report = ReportModel.testMake(modules: [fsModule])
        let result = Formatter.format(report, filters: [.slow(duration: slowThreshold)], format: .list)
        XCTAssertEqual(result, """
WriterSpec
✅🕢 [100 ms] Check file exists
✅🕢 [200 ms] Read from file
⚠️🕢 [125 ms] Write to file
""")
    }
}

extension FormatterTests {
    var generalReport: ReportModel {
        // Module with all possible tests
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
        
        // Module with repeated tests
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
        
        // Module with skipped tests
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
                         duration: Measurement<UnitDuration> = .testMake()) -> Self {
        .init(status: status, duration: duration)
    }
}

extension Measurement where UnitType: UnitDuration {
    static func testMake(unit: UnitDuration = .milliseconds,
                         value: Double = 0) -> Measurement<UnitDuration> {
        .init(value: value, unit: unit)
    }
    
    static func * (left: Self, right: Int) -> Self {
        .init(value: left.value * Double(right), unit: left.unit)
    }
    
    static func / (left: Self, right: Int) -> Self {
        .init(value: left.value / Double(right), unit: left.unit)
    }
}
