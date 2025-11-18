//
//  TestResultsDTO.swift
//
//
//  Created by Aleksey Berezka on 2025-01-XX.
//

import Foundation

/// New format DTO for test-results tests command
struct TestResultsDTO: Decodable {
    let devices: [Device]
    let testNodes: [TestNode]
}

extension TestResultsDTO {
    struct Device: Decodable {
        let architecture: String
        let deviceId: String
        let deviceName: String
        let modelName: String
        let osBuildNumber: String
        let osVersion: String
        let platform: String
    }
}

extension TestResultsDTO {
    struct TestNode: Decodable {
        let children: [TestNode]?
        let duration: String?
        let durationInSeconds: Double?
        let name: String
        let nodeIdentifier: String?
        let nodeIdentifierURL: String?
        let nodeType: NodeType
        let result: Result?
        let details: String?
    }
}

extension TestResultsDTO.TestNode {
    enum NodeType: String, Decodable {
        case testCase = "Test Case"
        case testSuite = "Test Suite"
        case unitTestBundle = "Unit test bundle"
        case repetition = "Repetition"
        case failureMessage = "Failure Message"
    }

    enum Result: String, Decodable {
        case passed = "Passed"
        case failed = "Failed"
        case skipped = "Skipped"
        case expectedFailure = "Expected Failure"
    }

    /// Extracts failure message from children nodes
    var failureMessage: String? {
        guard let children = children else { return nil }
        return children.first { $0.nodeType == .failureMessage }?.name
    }

    /// Extracts skip message from children nodes
    var skipMessage: String? {
        guard let children = children else { return nil }
        return children.first { $0.nodeType == .failureMessage && name.contains("skipped") }?.name
    }
}
