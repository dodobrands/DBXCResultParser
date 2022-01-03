import XCTest
@testable import TestParser

final class ReportParserTests: XCTestCase {

    func test() throws {
        _ = try ReportParser(xcresultPath: TestsConstants.unitTestsReportPath)
    }
}

