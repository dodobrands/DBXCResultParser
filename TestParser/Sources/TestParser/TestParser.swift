import Foundation

public class XCResultParser {
    let filePath: URL
    let shell: (_ command: String...) -> Int32
    
    public init(filePath: URL,
                shell: @escaping (_ command: String...) -> Int32) {
        self.filePath = filePath
        self.shell = shell
    }
    
    public func parse() throws -> URL {
//        guard filePath.startAccessingSecurityScopedResource() else {
//            // Handle the failure here.
//            throw Error.noAccess
//        }
//
//        // Make sure you release the security-scoped resource when you are done.
//        defer { filePath.stopAccessingSecurityScopedResource() }
        
        let reportFileName = "report.json"
        let reportPath = filePath.deletingLastPathComponent().appendingPathComponent(reportFileName)
        
        let command = "xcrun xcresulttool get --path \(filePath.path) --format json"
        _ = self.shell(command)
        
        return reportPath
    }
    
    enum Error: Swift.Error {
        case noAccess
    }
}

public class ReportParser {
    let filePath: URL
    let parser: JSONFailParser
    
    public init(filePath: URL) {
        self.filePath = filePath
        self.parser = JSONFailParser(filePath: filePath)
    }
    
    private func report() throws -> Report {
        try parser.parse()
    }

    public func parseList() throws -> String {
        let failedTests = try report().failedNames()
        let failedTestsFormatted = failureReport(failedTests)

        return failedTestsFormatted
    }

    public func parseTotalTests() throws -> String {
        return try report().total()
    }

    public func parseFailedTests() throws -> String {
        return try report().failed()
    }

    public func parseSkippedTests() throws -> String {
        return try report().skipped()
    }

    public func parseTestsRefFromTests() throws -> String {
        return try report().testsRefID()
    }

    public func parseFlakyReport() throws -> String {
        let report: TestsRefReport = try parser.parse()

        let testResults = report.testResults()
        let flackyResults = searchFlackyTests(testResults)
        let formattedFlackyResult = formattedReport(flackyResults, separator: "/", prefix: "❔")

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
        case .flakyReport:
            return try parseFlakyReport()
        }
    }
}

class FileParser {
    let filePath: URL
    
    init(filePath: URL) {
        self.filePath = filePath
    }
    
    func data() throws -> Data {
        try Data(contentsOf: filePath)
    }
}

class JSONFailParser: FileParser {
    
    func parse<ReportType: Decodable>() throws -> ReportType {
        let report = try JSONDecoder()
            .decode(ReportType.self, from: data())
        return report
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

func searchFlackyTests(_ testResults: [String: [String]]) -> [String] {
    var result = [String]()
    for testName in testResults.keys {
        if testResults[testName]?.contains(TestResult.failure.rawValue) == true {
            if testResults[testName]?.contains(TestResult.success.rawValue) == true {
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
    case flakyReport = "flakyReport"
}
