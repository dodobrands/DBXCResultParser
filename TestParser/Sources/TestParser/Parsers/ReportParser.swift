import Foundation

public class ReportParser {
    let fileData: Data
    
    public init(filePath: URL) throws {
        self.fileData = try Data(contentsOf: filePath)
    }
    
    var unitTestsReport: UnitTestsReport {
        get throws {
            return try JSONDecoder().decode(UnitTestsReport.self, from: fileData)
        }
    }
    
    var e2eTestsReport: E2ETestsReport {
        get throws {
            return try JSONDecoder().decode(E2ETestsReport.self, from: fileData)
        }
    }

    public func parseList() throws -> String {
        let failedTests = try unitTestsReport.failedNames()
        let failedTestsFormatted = failureReport(failedTests)

        return failedTestsFormatted
    }

    public func parseTotalTests() throws -> String {
        return try unitTestsReport.total()
    }

    public func parseFailedTests() throws -> String {
        return try unitTestsReport.failed()
    }

    public func parseSkippedTests() throws -> String {
        return try unitTestsReport.skipped()
    }

    public func parseTestsRefFromTests() throws -> String {
        return try unitTestsReport.testsRefID()
    }

    public func parseE2EFlaky() throws -> String {
        let report = try e2eTestsReport

        let testResults = report.testResults()
        let flackyResults = searchE2EFlacky(testResults)
        let formattedFlackyResult = formattedReport(flackyResults, separator: "/", prefix: "🟡")

        return formattedFlackyResult
    }

    public func parseE2EFailed() throws -> String {
        let report = try e2eTestsReport

        let testResults = report.testResults()
        let flackyResults = searchE2EFailed(testResults)
        let formattedFlackyResult = formattedReport(flackyResults, separator: "/", prefix: "🔴")

        return formattedFlackyResult
    }

    public func parse(mode: ParserMode) throws -> String {
        switch mode {
        case .total:
            return try parseTotalTests()
        case .skipped:
            return try parseSkippedTests()
        case .failed:
            return try parseFailedTests()
        case .list:
            return try parseList()
        case .testsRef:
            return try parseTestsRefFromTests()
        case .flakyE2E:
            return try parseE2EFlaky()
        case .failedE2E:
            return try parseE2EFailed()
        }
    }
}

func failureReport(_ input: [String]) -> String {
    return formattedReport(input, separator: ".", prefix: "❌")
}

func formattedReport(_ input: [String],
                     separator: String.Element,
                     prefix: String) -> String {
    let tests = input.map { fullName -> Test in
        let parts = fullName.split(separator: separator)
        return Test(suit: String(parts[0]),
                    name: String(parts[1]))
    }
    
    let suitsDict = Dictionary(grouping: tests) { pair in
        pair.suit
    }
    .map({ (key: String, values: [Test]) in
        Suit(name: key, tests: values.map({ test in test.name }))
    })

    let groups2 = suitsDict
        .map { suitDict in
            SuitDescr(name: suitDict.name,
                      tests: suitDescription(suit: suitDict,
                                             prefix: prefix))
        }
        .sorted { SuitDescr1, SuitDescr2 in
            SuitDescr1.name < SuitDescr2.name
        }

    return groups2.map({ suitDescr in
        suitDescr.tests
    }).joined(separator: "\n\n")
}

func suitDescription(suit: Suit, prefix: String) -> String {
    """
\(suit.name):
\(suitTests(suit.tests, prefix: prefix))
"""
}

func formattedTestRefReport(_ input: [String: [String]]) -> String {
    input
        .map { $0 + ": " + $1.joined(separator: ", ") }
        .joined(separator: "\n")
}

func searchE2EFlacky(_ testResults: [String: [String]]) -> [String] {
    var result: [String] = []
    for testName in testResults.keys {
        if testResults[testName]?.contains(TestResult.failure.rawValue) == true {
            if testResults[testName]?.contains(TestResult.success.rawValue) == true {
                result.append(testName)
            }
        }
    }
    return result
}

func searchE2EFailed(_ testResults: [String: [String]]) -> [String] {
    var result: [String] = []
    for testName in testResults.keys {
        if testResults[testName]?.contains(TestResult.failure.rawValue) == true {
            if testResults[testName]?.contains(TestResult.success.rawValue) == false {
                result.append(testName)
            }
        }
    }
    return result
}

public enum TestResult: String {
//    Failure, Success
    case failure = "Failure"
    case success = "Success"
}

public enum ParserMode: String {
    case total = "total"
    case skipped = "skipped"
    case failed = "failed"
    case list = "list"
    case testsRef = "testsRef"
    case flakyE2E = "flakyE2E"
    case failedE2E = "failedE2E"
}