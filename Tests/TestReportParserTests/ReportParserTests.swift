import XCTest
@testable import TestReportParser

final class ReportParserTests: XCTestCase {

    func test() throws {
        _ = try ReportParser(xcresultPath: TestsConstants.unitTestsReportPath)
    }
}

