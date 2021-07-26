//
//  File.swift
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

func suitTests(_ suit: [String]) -> String {
    suit.map({ test in
        "❌ \(test)"
    }).joined(separator: "\n")
}


struct Report: Codable {
    let issues: Issues
    
    func failedNames() throws -> [String] {
        return issues.testFailureSummaries?._values.compactMap { value in
            return value.testCaseName._value
        } ?? []
    }
    
    func summary() -> String {
        return "Total: 195, failed: 2"
    }
}

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
