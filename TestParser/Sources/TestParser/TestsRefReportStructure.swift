//
//  TestsRefReportStructure.swift
//
//
//  Created by Станислав Карпенко on 14.12.2021.
//

import Foundation

// .summaries._values[].testableSummaries._values[].tests._values[].subtests._values[].subtests._values[].subtests._values[].name._value
struct TestsRefReport: Decodable {
    let summaries: Summaries

    func testResults() -> [String: [String]] {
        var result = [String: [String]]()
        let xx = summaries.testableSummaries[0].tests[0]._values[0].subtests._values[0].subtests._values
        
        xx.forEach { thirdSubtestsValue in
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
}

struct TestsValue: Decodable {
    let subtests: FirstSubtests
}

// 1
// subtests._values[].subtests._values[].subtests._values[].name._value
struct FirstSubtests: Decodable {
    let _values: [FirstSubtestsValue]
}

struct FirstSubtestsValue: Decodable {
    let subtests: SecondSubtestsValue
}

// 2
// subtests._values[].subtests._values[].name._value
struct SecondSubtestsValue: Decodable {
    let _values: [ThirdSubtestsValue]
}

struct ThirdSubtestsValue: Decodable {
    let tests: FinalSubtests
    
    enum Keys: String, CodingKey {
        case tests = "subtests"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        self.tests = try container.decode(FinalSubtests.self, forKey: .tests)
    }
}

struct FinalSubtests: Decodable {
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
