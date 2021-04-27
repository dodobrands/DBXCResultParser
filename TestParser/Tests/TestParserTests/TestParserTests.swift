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

class JSONFailParser {

    let filePath: URL

    init(filePath: URL) {
        self.filePath = filePath
    }

    func parse() throws -> Report {
        let data = try Data(contentsOf: filePath)
        let report: Report = try JSONDecoder().decode(Report.self, from: data)

        return report
    }

    func failedNames() throws -> [String] {
        let report = try parse()
        return report.issues.testFailureSummaries._values.map { value in
            return value.testCaseName._value
        }

    }
}

class ReportParser {
    let folder: URL

    init(folder: URL) {
        self.folder = folder
    }

    func parse() throws -> [String] {

        shell("xcrun xcresulttool get --path E2ETests.xcresult --format json >> report.json")

        let json = folder.appendingPathComponent("report.json")

        let failedTests = try JSONFailParser(filePath: json).failedNames()

        return failedTests
    }
}



@discardableResult
func shell(_ args: String...) -> Int32 {
    let task = Process()
    task.launchPath = "/usr/bin/env"
    task.arguments = args
    task.launch()
    task.waitUntilExit()
    return task.terminationStatus
}


struct Report: Codable {
    let issues: Issues
}

struct Issues: Codable {
    let testFailureSummaries: TestFailureSummaries
}

struct TestFailureSummaries: Codable {
    let _values: [FailureValue]
}

struct FailureValue: Codable {
    let testCaseName: TestCaseName
}

struct TestCaseName: Codable {
    let _value: String
}




