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

        let names = ["AuthorizationTests.test_guest_can_login_in_russia_with_lithuania_phone()",
                     "AuthorizationTests.test_guest_can_login_in_russia_with_estonia_phone()"]
        XCTAssertEqual(try parser.failedNames(),
                       names)
        
        
    }
    
    func testNameFormatting_shouldSort_andExtractSuit() {
        let names = [
            "ContactsTabTests.test_kazahstan_legal_documents_terms_of_use()",
            "ContactsTabTests.test_uk_legal_documents_terms_and_conditions()",
            "AuthorizationTests.test_guest_can_login_in_russia_with_lithuania_phone()",
            "AuthorizationTests.test_guest_can_login_in_russia_with_estonia_phone()",
        ]
        
        XCTAssertEqual(formattedReport(names),
                       """
AuthorizationTests:
❌ test_guest_can_login_in_russia_with_lithuania_phone()
❌ test_guest_can_login_in_russia_with_estonia_phone()

ContactsTabTests:
❌ test_kazahstan_legal_documents_terms_of_use()
❌ test_uk_legal_documents_terms_and_conditions()
""")
    }
    
    

    static var allTests = [
        ("testExample", testExample),
    ]
}
