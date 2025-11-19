import Foundation

struct TestResultsDTO: Decodable {
    let testNodes: [TestNode]
}

extension TestResultsDTO {
    struct TestNode: Decodable {
        let children: [TestNode]?
        let durationInSeconds: Double?
        let name: String
        let nodeType: NodeType
        let result: Result?
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
        case arguments = "Arguments"
        case runtimeWarning = "Runtime Warning"
    }

    enum Result: String, Decodable {
        case passed = "Passed"
        case failed = "Failed"
        case skipped = "Skipped"
        case expectedFailure = "Expected Failure"
    }

    /// Extracts failure message from children nodes
    /// Extracts message after "failed -" separator (e.g., "File.swift:51: failed - Failure message" -> "Failure message")
    var failureMessage: String? {
        guard let children = children,
            let messageNode = children.first(where: { $0.nodeType == .failureMessage })
        else { return nil }
        let message = messageNode.name
        if let range = message.range(of: "failed -") {
            return String(message[range.upperBound...]).trimmingCharacters(in: .whitespaces)
        }
        return message
    }

    /// Extracts skip message from children nodes
    /// Extracts message after "skipped -" separator (e.g., "Test skipped - Skip message" -> "Skip message")
    var skipMessage: String? {
        guard let children = children else { return nil }
        let messageNode = children.first {
            $0.nodeType == .failureMessage && $0.name.lowercased().contains("skip")
        }
        guard let message = messageNode?.name else { return nil }
        if let range = message.range(of: "skipped -") {
            return String(message[range.upperBound...]).trimmingCharacters(in: .whitespaces)
        }
        return message
    }
}
