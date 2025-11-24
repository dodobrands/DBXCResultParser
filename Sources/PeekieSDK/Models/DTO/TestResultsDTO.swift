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
    enum NodeType: Decodable, Equatable {
        case testCase
        case testSuite
        case unitTestBundle
        case repetition
        case failureMessage
        case testPlan
        case arguments
        case runtimeWarning
        case unknown(String)

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(String.self)

            switch rawValue {
            case "Test Case":
                self = .testCase
            case "Test Suite":
                self = .testSuite
            case "Unit test bundle":
                self = .unitTestBundle
            case "Repetition":
                self = .repetition
            case "Failure Message":
                self = .failureMessage
            case "Test Plan":
                self = .testPlan
            case "Arguments":
                self = .arguments
            case "Runtime Warning":
                self = .runtimeWarning
            default:
                self = .unknown(rawValue)
            }
        }

        static func == (lhs: NodeType, rhs: NodeType) -> Bool {
            switch (lhs, rhs) {
            case (.testCase, .testCase),
                (.testSuite, .testSuite),
                (.unitTestBundle, .unitTestBundle),
                (.repetition, .repetition),
                (.failureMessage, .failureMessage),
                (.testPlan, .testPlan),
                (.arguments, .arguments),
                (.runtimeWarning, .runtimeWarning):
                return true
            case (.unknown(let lhsValue), .unknown(let rhsValue)):
                return lhsValue == rhsValue
            default:
                return false
            }
        }
    }

    enum Result: String, Decodable {
        case passed = "Passed"
        case failed = "Failed"
        case skipped = "Skipped"
        case expectedFailure = "Expected Failure"
    }

    /// Extracts failure message from children nodes
    /// Extracts message after "failed -" separator (e.g., "File.swift:51: failed - Failure message" -> "Failure message")
    /// For Swift Testing format, extracts message after "Issue recorded: " (e.g., "File.swift:56: Issue recorded: Failure message" -> "Failure message")
    var failureMessage: String? {
        guard let children = children,
            let messageNode = children.first(where: { $0.nodeType == .failureMessage })
        else { return nil }
        let message = messageNode.name
        // Try Swift Testing format first: "Issue recorded: "
        if let range = message.range(of: "Issue recorded: ") {
            return String(message[range.upperBound...]).trimmingCharacters(in: .whitespaces)
        }
        // Fallback to XCTest format: "failed -"
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
