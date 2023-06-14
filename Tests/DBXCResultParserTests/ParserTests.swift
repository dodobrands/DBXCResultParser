import XCTest
@testable import DBXCResultParser

final class ParserTests: XCTestCase {

    func test() throws {
        XCTAssertNoThrow(try Parser(xcresultPath: Constants.unitTestsReportPath))
    }
}

