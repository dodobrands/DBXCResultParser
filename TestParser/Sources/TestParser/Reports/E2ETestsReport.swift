//
//  E2ETestsReport.swift
//
//
//  Created by Станислав Карпенко on 14.12.2021.
//

import Foundation

// .summaries._values[].testableSummaries._values[].tests._values[].subtests._values[].subtests._values[].subtests._values[].name._value
struct E2ETestsReport: Decodable {
    let summaries: Summaries

    func testResults() -> [String: [String]] {
        var result = [String: [String]]()
        let testSuites = summaries.testableSummaries[0].tests[0].allTests[0].testScheme[0]._values
        
        testSuites.forEach { thirdSubtestsValue in
            thirdSubtestsValue.tests._values.forEach { testsRefReportData in
                if result[testsRefReportData.identifier._value] == nil {
                    result[testsRefReportData.identifier._value] = [testsRefReportData.testStatus._value]
                } else {
                    result[testsRefReportData.identifier._value]?.append(testsRefReportData.testStatus._value)
                }
            }
        }
        return result
    }
}

struct Summaries: Decodable {
    let _values: [SummariesValue]
    
    var testableSummaries: [TestableSummaries] {
        _values.map { value in
            value.testableSummaries
        }
    }
}

struct SummariesValue: Decodable {
    let testableSummaries: TestableSummaries
}

// testableSummaries._values[].tests._values[].subtests._values[].subtests._values[].subtests._values[].name._value
struct TestableSummaries: Decodable {
    let _values: [TestableSummariesValue]
    
    var tests: [Tests] {
        _values.map { value in
            value.tests
        }
    }
}

struct TestableSummariesValue: Decodable {
    let tests: Tests
}

// tests._values[].subtests._values[].subtests._values[].subtests._values[].name._value
struct Tests: Decodable {
    let _values: [TestsValue]

    var allTests: [AllTests] {
        _values.map { value in
            value.subtests
        }
    }
}

struct TestsValue: Decodable {
    let subtests: AllTests
}

// 1
// subtests._values[].subtests._values[].subtests._values[].name._value
struct AllTests: Decodable {
    let _values: [AllTestsValue]

    var testScheme: [TestSchemeValue] {
        _values.map { value in
            value.subtests
        }
    }
}

struct AllTestsValue: Decodable {
    let subtests: TestSchemeValue
}

// 2
// subtests._values[].subtests._values[].name._value
struct TestSchemeValue: Decodable {
    let _values: [TestSuiteValue]
}

struct TestSuiteValue: Decodable {
    let tests: TestResultData
    
    enum Keys: String, CodingKey {
        case tests = "subtests"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        self.tests = try container.decode(TestResultData.self, forKey: .tests)
    }
}

struct TestResultData: Decodable {
    let _values: [TestsRefReportData]
}

// 3
// subtests._values[].name._value
struct TestsRefReportData: Decodable {
    let identifier: IdentifierTest
    let summaryRef: SummaryRef
    let name: NameReportData
    let testStatus: TestStatus
}

struct IdentifierTest: Decodable {
    let _value: String
}

struct SummaryRef: Decodable {
    let id: IdSummaryRef
}

struct IdSummaryRef: Decodable {
    let _value: String
}

struct NameReportData: Decodable {
    let _value: String
}

struct TestStatus: Decodable {
    let _value: String
}
