//
//  TestsRefReportStructure.swift
//
//
//  Created by Станислав Карпенко on 14.12.2021.
//

import Foundation

             // .summaries._values[].testableSummaries._values[].tests._values[].subtests._values[].subtests._values[].subtests._values[].name._value
struct TestsRefReport: Codable {
    let summaries: Summaries

    func testsNames() -> [String] {
        return summaries._values[0].testableSummaries._values[0].tests._values[0].subtests._values[0].subtests._values[0].subtests._values.compactMap { value in
            value.name._value
        }
    }
}

struct Summaries: Codable {
    let _values: [SummariesValue]
}

struct SummariesValue: Codable {
    let testableSummaries: TestableSummaries
}

// testableSummaries._values[].tests._values[].subtests._values[].subtests._values[].subtests._values[].name._value
struct TestableSummaries: Codable {
    let _values: [TestableSummariesValue]
}

struct TestableSummariesValue: Codable {
    let tests: Tests
}

// tests._values[].subtests._values[].subtests._values[].subtests._values[].name._value
struct Tests: Codable {
    let _values: [TestsValue]
}

struct TestsValue: Codable {
    let subtests: FirstSubtests
}

// 1
// subtests._values[].subtests._values[].subtests._values[].name._value
struct FirstSubtests: Codable {
    let _values: [FirstSubtestsValue]
}

struct FirstSubtestsValue: Codable {
    let subtests: SecondSubtestsValue
}

// 2
// subtests._values[].subtests._values[].name._value
struct SecondSubtestsValue: Codable {
    let _values: [ThirdSubtestsValue]
}


struct ThirdSubtestsValue: Codable {
    let subtests: FinalSubtests
}

struct FinalSubtests: Codable {
    let _values: [TestsRefReportData]
}
// 3
// subtests._values[].name._value
struct TestsRefReportData: Codable {
    let name: NameReportData
}

struct NameReportData: Codable {
    let _value: String
}

