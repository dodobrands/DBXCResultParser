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
        case testPlan = "Test Plan"
    }

    enum Result: String, Decodable {
        case passed = "Passed"
        case failed = "Failed"
        case skipped = "Skipped"
        case expectedFailure = "Expected Failure"
    }

    /// Extracts failure message from children nodes
    /// Extracts message after "-" separator (e.g., "File.swift:51: failed - Failure message" -> "Failure message")
    var failureMessage: String? {
        guard let children = children,
            let messageNode = children.first(where: { $0.nodeType == .failureMessage })
        else { return nil }
        let parts = messageNode.name.split(separator: "-", maxSplits: 1)
        return parts.count > 1
            ? String(parts[1]).trimmingCharacters(in: .whitespaces) : messageNode.name
    }

    /// Extracts skip message from children nodes
    var skipMessage: String? {
        guard let children = children else { return nil }
        // Skip message can be in Failure Message node or directly as a child
        let messageNode = children.first {
            $0.nodeType == .failureMessage && $0.name.lowercased().contains("skip")
        }
        return messageNode?.name
    }
}
