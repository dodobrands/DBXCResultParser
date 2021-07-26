import XCTest
@testable import TestParser

final class FormatteTests: XCTestCase {
    
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
}
