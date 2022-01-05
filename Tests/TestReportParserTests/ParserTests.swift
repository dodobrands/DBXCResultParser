import XCTest
@testable import TestReportParser

final class ParserTests: XCTestCase {

    func test() throws {
        _ = try Parser(xcresultPath: Constants.unitTestsReportPath)
    }
}

