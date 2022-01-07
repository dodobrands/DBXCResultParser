import XCTest
@testable import TestReportParser

final class ParserTests: XCTestCase {

    func test() throws {
        XCTAssertNoThrow(try Parser(xcresultPath: Constants.unitTestsReportPath))
    }
}

