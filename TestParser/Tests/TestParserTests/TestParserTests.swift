import XCTest
@testable import TestParser

final class TestParserTests: XCTestCase {

    var reportPath: URL!

    override func setUpWithError() throws {
        reportPath = try XCTUnwrap(Bundle.module.url(forResource: "report", withExtension: "json"))
    }

    func testExample() throws {
        let parser = JSONFailParser(filePath: reportPath)

        let report = try parser.parse()

        XCTAssertEqual(report.issues.testFailureSummaries._values[0].testCaseName._value,
                       "AuthorizationTests.test_guest_can_login_in_russia_with_lithuania_phone()")
        XCTAssertEqual(report.issues.testFailureSummaries._values[1].testCaseName._value,
                       "AuthorizationTests.test_guest_can_login_in_russia_with_estonia_phone()")

        XCTAssertEqual(try parser.failedNames(),
                       ["AuthorizationTests.test_guest_can_login_in_russia_with_lithuania_phone()",
                        "AuthorizationTests.test_guest_can_login_in_russia_with_estonia_phone()"])
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
