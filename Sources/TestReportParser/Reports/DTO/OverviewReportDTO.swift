//
//  OverviewReportDTO.swift
//
//
//  Created by Mikhail Rubanov on 24.05.2021.
//

import Foundation

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

func suitTests(_ suit: [String], prefix: String) -> String {
    suit.map({ test in
        "\(prefix) \(test)"
    }).joined(separator: "\n")
}

struct OverviewReportDTO: Codable {
    let actions: Actions

    func failedNames() throws -> [String] {
        return actions._values[0].actionResult.issues.testFailureSummaries?._values.compactMap { value in
            value.testCaseName._value
        } ?? []
    }

    func summary() -> String {
        let countOfTests = actions._values[0].actionResult.metrics.testsCount._value
        let countOfFailureTests = actions._values[0].actionResult.metrics.testsFailedCount?._value ?? "0"
        let result = "Total: \(countOfTests), Failed: \(countOfFailureTests)"
        return result
    }

    func total() -> String {
        actions._values[0].actionResult.metrics.testsCount._value
    }

    func failed() -> String {
        actions._values[0].actionResult.metrics.testsFailedCount?._value ?? "0"
    }

    func skipped() -> String {
        actions._values[0].actionResult.metrics.testsSkippedCount?._value ?? "0"
    }

    func testsRefID() -> String {
        actions._values[0].actionResult.testsRef.id._value
    }
}

// metrics for func summary
struct Actions: Codable {
    let _values: [ActionValue]
}

struct ActionValue: Codable {
    let actionResult: ActionResult
}

struct ActionResult: Codable {
    let issues: Issues
    let metrics: Metrics
    let testsRef: TestsRef
}

// issues for failed tests
struct Issues: Codable {
    let testFailureSummaries: TestFailureSummaries?
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

// metrics for func summary

struct Metrics: Codable {
    let testsCount: TestsCount
    let testsFailedCount: TestsFailedCount?
    let testsSkippedCount: TestsSkippedCount?
}

struct TestsCount: Codable {
    let _value: String
}

struct TestsFailedCount: Codable {
    let _value: String
}

struct TestsSkippedCount: Codable {
    let _value: String
}

// testsRef id for detail analize
struct TestsRef: Codable {
    let id: TestsRefID
}

struct TestsRefID: Codable {
    let _value: String
}
