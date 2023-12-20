import XCTest
@testable import DBXCResultParser
import DBXCResultParserTestHelpers

final class DBXCTextFormatterTests: XCTestCase {
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
        let formatter = DBXCTextFormatter()
        formatter.format = .list
        formatter.locale = locale
        let result = formatter.format(.genericReport)
        
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
⏭️ enabledNotifications
""")
    }
    
    func test_testResult_success_list() {
        let formatter = DBXCTextFormatter()
        formatter.format = .list
        formatter.locale = locale
        let result = formatter.format(.genericReport, testResults: [.success])
        
        XCTAssertEqual(result,
                       """
AuthSpec
✅ login

NetworkSpec
✅ MakeRequest
""")
    }
    
    func test_testResult_any_count() {
        let formatter = DBXCTextFormatter()
        formatter.format = .count
        formatter.locale = locale
        let result = formatter.format(.genericReport)
        
        XCTAssertEqual(result, "7 (0 sec)")
    }
    
    func test_testResult_failure_count() {
        let formatter = DBXCTextFormatter()
        formatter.format = .count
        formatter.locale = locale
        let result = formatter.format(.genericReport, testResults: [.failure])
        
        XCTAssertEqual(result, "3 (0 sec)")
    }
}

extension DBXCReportModel {
    static var genericReport: DBXCReportModel {
        // Module with all possible tests
        let profileModule = DBXCReportModel.Module.testMake(
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
        let networkModule = DBXCReportModel.Module.testMake(
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
        let notificationsModule = DBXCReportModel.Module.testMake(
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
