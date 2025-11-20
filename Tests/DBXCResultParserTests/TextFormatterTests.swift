import Foundation
import PeekieTestHelpers
import Testing

@testable import peekiesdk

@Suite
struct TextFormatterTests {
    let locale = Locale(identifier: "en-US")

    @Test
    func test_testResult_any_list() {
        let formatter = TextFormatter()
        let result = formatter.format(.genericReport, format: .list, locale: locale)

        #expect(
            result == """
                AuthSpec
                ✅ login
                ❌ logout (Failed to logout)
                ⚠️ openSettings
                ⏭️ parse_performance (Parse is very slow, turned off tests)
                🤡 rename_user (Rename is temporary broken)

                CaptchaSpec
                ❌ Another Handle Request
                ❌ Handle Request

                NetworkSpec
                ✅ MakeRequest

                NotificationsSetupServiceTests
                ⏭️ enabledNotifications
                """)
    }

    @Test
    func test_testResult_success_list() {
        let formatter = TextFormatter()
        let result = formatter.format(
            .genericReport, include: [.success], format: .list, locale: locale)

        #expect(
            result == """
                AuthSpec
                ✅ login

                NetworkSpec
                ✅ MakeRequest
                """)
    }

    @Test
    func test_testResult_any_count() {
        let formatter = TextFormatter()
        let result = formatter.format(.genericReport, format: .count, locale: locale)

        #expect(result == "9 (0 sec)")
    }

    @Test
    func test_testResult_failure_count() {
        let formatter = TextFormatter()
        let result = formatter.format(
            .genericReport, include: [.failure], format: .count, locale: locale)

        #expect(result == "3 (0 sec)")
    }
}

extension ReportModel {
    static var genericReport: ReportModel {
        // Module with all possible tests
        let profileModule = ReportModel.Module.testMake(
            name: "Profile",
            files: [
                .testMake(
                    name: "AuthSpec",
                    repeatableTests: [
                        .failed(named: "logout", message: "Failed to logout"),
                        .succeeded(named: "login"),
                        .mixedFailedSucceeded(named: "openSettings"),
                        .expectedFailed(
                            named: "rename_user", message: "Rename is temporary broken"),
                        .skipped(
                            named: "parse_performance",
                            message: "Parse is very slow, turned off tests"),
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
                        .failed(named: "Another Handle Request", times: 2),
                    ]
                ),
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
                notificationsModule,
            ]
        )
    }
}
