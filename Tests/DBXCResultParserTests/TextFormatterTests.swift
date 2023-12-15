import XCTest
@testable import DBXCResultParser

final class FormatterTests: XCTestCase {
    var locale: Locale!
    override func setUpWithError() throws {
        try super.setUpWithError()
        locale = Locale(identifier: "en-US")
    }
    
    override func tearDownWithError() throws {
        locale = nil
        try super.tearDownWithError()
    }
    
    func test_testResult_any_list() {
        let formatter = TextFormatter(format: .list, locale: locale)
        let result = formatter.format(generalReport)
        
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
    
    func test_testResult_success_list() {
        let formatter = TextFormatter(format: .list, locale: locale)
        let result = formatter.format(generalReport, testResults: [.success])
        
        XCTAssertEqual(result,
                       """
AuthSpec
✅ login

NetworkSpec
✅ MakeRequest
""")
    }
    
    func test_testResult_any_count() {
        let formatter = TextFormatter(format: .count, locale: locale)
        let result = formatter.format(generalReport)
        
        XCTAssertEqual(result, "7 (0 sec)")
    }
    
    func test_testResult_failure_count() {
        let formatter = TextFormatter(format: .count, locale: locale)
        let result = formatter.format(generalReport, testResults: [.failure])
        
        XCTAssertEqual(result, "3 (0 sec)")
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
    
    func slowReport(duration: Duration) -> ReportModel {
        .testMake(
            modules: [
                .testMake(
                    name: "FSModule",
                    files: [
                        .testMake(
                            name: "WriterSpec",
                            repeatableTests: [
                                .testMake(
                                    name: "Check folder exists",
                                    tests: [
                                        .testMake(status: .failure, duration: duration / 2)
                                    ]
                                ),
                                .testMake(
                                    name: "Check file exists",
                                    tests: [
                                        .testMake(status: .success, duration: duration)
                                    ]
                                ),
                                .testMake(
                                    name: "Read from file",
                                    tests: [
                                        .testMake(status: .success, duration: duration * 2)
                                    ]
                                ),
                                .testMake(
                                    name: "Write to file",
                                    tests: [
                                        .testMake(status: .failure, duration: duration / 2),
                                        .testMake(status: .success, duration: duration * 2),
                                    ]
                                )
                            ]
                        )
                    ]
                )
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
    static func testMake(name: String = "", files: Set<File> = [], coverage: Coverage = .testMake()) -> Self {
        .init(name: name, files: files, coverage: coverage)
    }
}

extension ReportModel.Module.Coverage {
    static func testMake(name: String = "",
                         coveredLines: Int = 0,
                         totalLines: Int = 0,
                         coverage: Double = 0.0) -> Self {
        Self(name: name,
             coveredLines: coveredLines,
             totalLines: totalLines,
             coverage: coverage)
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
                         duration: Duration = .testMake()) -> Self {
        .init(status: status, duration: duration)
    }
}

extension Measurement where UnitType: UnitDuration {
    static func testMake(unit: UnitDuration = .milliseconds,
                         value: Double = 0) -> Duration {
        .init(value: value, unit: unit)
    }
    
    static func * (left: Self, right: Int) -> Self {
        .init(value: left.value * Double(right), unit: left.unit)
    }
    
    static func / (left: Self, right: Int) -> Self {
        .init(value: left.value / Double(right), unit: left.unit)
    }
}
