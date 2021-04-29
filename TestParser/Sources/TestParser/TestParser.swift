import Foundation

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

public class ReportParser {
    let folder: URL
    
    public init(folder: URL) {
        self.folder = folder
    }
    
    public func parse() throws -> String {
        
//        shell("ls")
//
//        let command = "xcrun xcresulttool get --path E2ETests.xcresult --format json > report.json"
//        shell(command)
        
        let failedTests = try JSONFailParser(filePath: folder).failedNames()
        
        return formattedReport(failedTests)
    }
}

func formattedReport(_ input: [String]) -> String {
    let pairs = input.map { fullName -> Test in
        let parts = fullName.split(separator: ".")
        return Test(suit: String(parts[0]),
                    name: String(parts[1]))
    }
    
    let suits = Dictionary(grouping: pairs) { pair in
        pair.suit
    }
    .map({ (key: String, values: [Test]) in
        Suit(name: key, tests: values.map({ test in test.name }))
    })
    
    let groups2 = suits
        .map  { suit in
            SuitDescr(name: suit.name, tests: suitDescription(suit: suit))
        }
        .sorted { SuitDescr1, SuitDescr2 in
            SuitDescr1.name < SuitDescr2.name
        }
            
    
    return groups2.map({ suitDescr in
        suitDescr.tests
    }).joined(separator: "\n\n")
}

func suitDescription(suit: Suit) -> String {
    """
\(suit.name):
\(suitTests(suit.tests))
"""
}

struct Test {
    let suit: String
    let name: String
}

struct Suit {
    let name: String
    let tests: [String]
}

struct SuitDescr {
    let name: String
    let tests: String
}

func suitTests(_ suit: [String]) -> String {
    suit.map({ test in
        "❌ \(test)"
    }).joined(separator: "\n")
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
