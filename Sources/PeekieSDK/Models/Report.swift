import Foundation

public struct Report {
    public let modules: Set<Module>
    public let coverage: Double?

    /// All warnings from all modules in this report
    public var warnings: [Module.File.Issue] {
        modules.flatMap { $0.warnings }
    }
}

extension Report {
    public struct Module: Hashable {
        public let name: String
        public internal(set) var files: Set<File>
        public let coverage: Coverage?

        public func hash(into hasher: inout Hasher) {
            hasher.combine(name)
        }

        public static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.name == rhs.name
        }

        /// All warnings from all files in this module
        public var warnings: [File.Issue] {
            files.flatMap { $0.warnings }
        }
    }

    public struct Coverage: Equatable {
        public let coveredLines: Int
        public let totalLines: Int
        public let coverage: Double
    }
}

extension Report.Module.File {
    public struct Coverage: Equatable {
        public let coveredLines: Int
        public let totalLines: Int
        public let coverage: Double

        init(
            coveredLines: Int,
            totalLines: Int,
            coverage: Double
        ) {
            self.coveredLines = coveredLines
            self.totalLines = totalLines
            self.coverage = coverage
        }

        init(from dto: FileCoverageDTO) {
            self.coveredLines = dto.coveredLines
            self.totalLines = dto.executableLines
            self.coverage = dto.lineCoverage
        }
    }
}

extension Report.Module {
    public struct File: Hashable {
        public let name: String
        public internal(set) var repeatableTests: Set<RepeatableTest>
        public internal(set) var warnings: [Issue]
        public let coverage: Coverage?

        public func hash(into hasher: inout Hasher) {
            hasher.combine(name)
        }

        public static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.name == rhs.name
        }
    }
}

extension Report.Module.File {
    public struct Issue: Equatable, Sendable {
        public let type: IssueType
        public let message: String

        public enum IssueType: String, Equatable, Sendable {
            case buildWarning = "Swift Compiler Warning"
        }
    }
}

extension Report.Module.File {
    public struct RepeatableTest: Hashable {
        public let name: String
        public internal(set) var tests: [Test]

        public func hash(into hasher: inout Hasher) {
            hasher.combine(name)
        }

        public static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.name == rhs.name
        }
    }
}

extension Report.Module.File.RepeatableTest {
    public struct PathNode: Equatable, Hashable {
        public let name: String
        public let type: NodeType
        public let result: Test.Status?
        public let duration: Measurement<UnitDuration>?
        public let message: String?

        public enum NodeType: Equatable, Hashable {
            case device
            case arguments
            case repetition

            init(from dtoNodeType: TestResultsDTO.TestNode.NodeType) {
                switch dtoNodeType {
                case .device:
                    self = .device
                case .arguments:
                    self = .arguments
                case .repetition:
                    self = .repetition
                default:
                    // This should not happen in normal flow, but handle gracefully
                    fatalError("Cannot convert \(dtoNodeType) to PathNode.NodeType")
                }
            }
        }

        init(
            name: String,
            type: NodeType,
            result: Test.Status? = nil,
            duration: Measurement<UnitDuration>? = nil,
            message: String? = nil
        ) {
            self.name = name
            self.type = type
            self.result = result
            self.duration = duration
            self.message = message
        }
    }

    public struct Test: Equatable {
        public let name: String
        public let status: Status
        public let duration: Measurement<UnitDuration>
        public let path: [PathNode]

        public init(
            name: String,
            status: Status,
            duration: Measurement<UnitDuration>,
            path: [PathNode]
        ) {
            self.name = name
            self.status = status
            self.duration = duration
            self.path = path
        }
    }

    public var combinedStatus: Test.Status {
        let statuses = tests.map { $0.status }
        if statuses.elementsAreEqual {
            return statuses.first ?? .success
        } else {
            return .mixed
        }
    }

    public var averageDuration: Measurement<UnitDuration> {
        assert(tests.map { $0.duration.unit }.elementsAreEqual)

        let unit = tests.first?.duration.unit ?? Test.defaultDurationUnit

        return .init(
            value: tests.map { $0.duration.value }.average(),
            unit: unit
        )
    }

    public var totalDuration: Measurement<UnitDuration> {
        assert(tests.map { $0.duration.unit }.elementsAreEqual)
        let value = tests.map { $0.duration.value }.sum()
        let unit = tests.first?.duration.unit ?? Test.defaultDurationUnit
        return .init(value: value, unit: unit)
    }

    /// Returns merged tests by merging repetitions (removing repetition nodes from paths)
    /// Status is mixed if repetitions had different statuses, otherwise uses parent node status
    public var mergedTests: [Test] {
        guard !tests.isEmpty else { return [] }

        // Group tests by path without last repetition element
        var pathToTests: [String: [Test]] = [:]

        for test in tests {
            let pathKey: String
            if test.path.last?.type == .repetition {
                // Remove last repetition element for grouping
                let pathWithoutRepetition = Array(test.path.dropLast())
                pathKey = self.pathKey(from: pathWithoutRepetition)
            } else {
                pathKey = self.pathKey(from: test.path)
            }

            if pathToTests[pathKey] == nil {
                pathToTests[pathKey] = []
            }
            pathToTests[pathKey]?.append(test)
        }

        var mergedResults: [Test] = []

        // Sort by path key to ensure consistent order
        let sortedKeys = pathToTests.keys.sorted()
        for key in sortedKeys {
            guard let groupTests = pathToTests[key] else { continue }
            if groupTests.count == 1 {
                // Single test - check if it ends with repetition
                let test = groupTests[0]
                if test.path.last?.type == .repetition {
                    // Merge: remove repetition, use parent status
                    let pathWithoutRepetition = Array(test.path.dropLast())
                    let parentNode = pathWithoutRepetition.last
                    let status = parentNode?.result ?? test.status
                    let duration = parentNode?.duration ?? test.duration

                    mergedResults.append(
                        Test(
                            name: self.name,
                            status: status,
                            duration: duration,
                            path: pathWithoutRepetition
                        ))
                } else {
                    // No repetition, keep as is
                    mergedResults.append(test)
                }
            } else {
                // Multiple tests - check if all end with repetition
                let allEndWithRepetition = groupTests.allSatisfy {
                    $0.path.last?.type == .repetition
                }
                if allEndWithRepetition {
                    // Merge repetitions
                    let firstTest = groupTests[0]
                    let pathWithoutRepetition = Array(firstTest.path.dropLast())

                    // Check if statuses differ
                    let statuses = groupTests.map { $0.status }
                    let statusesDiffer = !statuses.elementsAreEqual

                    let parentNode = pathWithoutRepetition.last
                    let status: Test.Status
                    if statusesDiffer {
                        status = .mixed
                    } else {
                        status = parentNode?.result ?? statuses.first ?? .unknown
                    }

                    let duration =
                        parentNode?.duration ?? groupTests.first?.duration
                        ?? Measurement(value: 0, unit: Test.defaultDurationUnit)

                    mergedResults.append(
                        Test(
                            name: self.name,
                            status: status,
                            duration: duration,
                            path: pathWithoutRepetition
                        ))
                } else {
                    // Not all end with repetition, keep all as is
                    mergedResults.append(contentsOf: groupTests)
                }
            }
        }

        // Sort results by path for consistent ordering
        return mergedResults.sorted { test1, test2 in
            let key1 = pathKey(from: test1.path)
            let key2 = pathKey(from: test2.path)
            return key1 < key2
        }
    }

    /// Creates a key from path for grouping
    private func pathKey(from path: [PathNode]) -> String {
        path.map { "\($0.name):\($0.type)" }.joined(separator: "|")
    }

    public func isSlow(_ duration: Measurement<UnitDuration>) -> Bool {
        let averageDuration = averageDuration
        let duration = duration.converted(to: averageDuration.unit)
        return averageDuration >= duration
    }
}

extension Report.Module.File.RepeatableTest.Test {
    public enum Status: String, Equatable, CaseIterable {
        case success
        case failure
        case expectedFailure
        case skipped

        // there were multiple retries with different results
        case mixed
        case unknown
    }
}

extension Set where Element == Report.Module.File.RepeatableTest {
    /// Filters tests based on statis
    /// - Parameter testResults: statuses to leave in result
    /// - Returns: set of elements matching any of the specified statuses
    public func filtered(testResults: [Report.Module.File.RepeatableTest.Test.Status])
        -> Set<Element>
    {
        guard !testResults.isEmpty else {
            return self
        }

        let results =
            testResults
            .flatMap { testResult -> Set<Element> in
                switch testResult {
                case .success:
                    return self.succeeded
                case .failure:
                    return self.failed
                case .mixed:
                    return self.mixed
                case .skipped:
                    return self.skipped
                case .expectedFailure:
                    return self.expectedFailed
                case .unknown:
                    return self.unknown
                }
            }

        return Set(results)
    }

    // Property that filters the collection to include only elements whose status is `.success`.
    var succeeded: Self {
        filter { $0.combinedStatus == .success }
    }

    // Property that filters the collection to include only elements whose status is `.failure`.
    var failed: Self {
        filter { $0.combinedStatus == .failure }
    }

    // Property that filters the collection to include only elements whose status is `.expectedFailure`.
    var expectedFailed: Self {
        filter { $0.combinedStatus == .expectedFailure }
    }

    // Property that filters the collection to include only elements whose status is `.skipped`.
    var skipped: Self {
        filter { $0.combinedStatus == .skipped }
    }

    // Property that filters the collection to include only elements whose status is `.mixed`.
    // This might indicate a combination of success and failure statuses or an intermediate state.
    var mixed: Self {
        filter { $0.combinedStatus == .mixed }
    }

    // Property that filters the collection to include only elements whose status is `.unknown`.
    // This status might be used when the status of an element has not been determined or is not applicable.
    var unknown: Self {
        filter { $0.combinedStatus == .unknown }
    }
}

extension Report.Module.File.RepeatableTest.Test {
    /// Initializes from TestResultsDTO.TestNode (Repetition node) with path
    init(
        from node: TestResultsDTO.TestNode,
        path: [Report.Module.File.RepeatableTest.PathNode],
        testCaseName: String
    ) throws {
        guard node.nodeType == .repetition else {
            throw Error.invalidNodeType
        }

        guard let result = node.result else {
            throw Error.missingResult
        }

        self.name = testCaseName

        switch result {
        case .passed:
            status = .success
        case .failed:
            status = .failure
        case .skipped:
            status = .skipped
        case .expectedFailure:
            status = .expectedFailure
        }

        let durationSeconds = node.durationInSeconds ?? 0.0
        self.duration = .init(value: durationSeconds * 1000, unit: Self.defaultDurationUnit)

        self.path = path
    }

    /// Initializes from TestResultsDTO.TestNode (Arguments node) with path
    init(
        from node: TestResultsDTO.TestNode,
        path: [Report.Module.File.RepeatableTest.PathNode],
        testCase: TestResultsDTO.TestNode
    ) {
        self.name = testCase.name

        let status: Status
        if let result = node.result {
            switch result {
            case .passed:
                status = .success
            case .failed:
                status = .failure
            case .skipped:
                status = .skipped
            case .expectedFailure:
                status = .expectedFailure
            }
        } else {
            // Fallback to test case result
            guard let testCaseResult = testCase.result else {
                status = .unknown
                self.status = status
                self.duration = .init(value: 0, unit: Self.defaultDurationUnit)
                self.path = path
                return
            }
            switch testCaseResult {
            case .passed:
                status = .success
            case .failed:
                status = .failure
            case .skipped:
                status = .skipped
            case .expectedFailure:
                status = .expectedFailure
            }
        }

        self.status = status

        let durationSeconds = node.durationInSeconds ?? testCase.durationInSeconds ?? 0.0
        self.duration = .init(value: durationSeconds * 1000, unit: Self.defaultDurationUnit)

        self.path = path
    }

    /// Initializes from TestResultsDTO.TestNode (Test Case node) with empty path
    init(from testCase: TestResultsDTO.TestNode) {
        self.name = testCase.name

        guard let result = testCase.result else {
            self.status = .unknown
            self.duration = .init(value: 0, unit: Self.defaultDurationUnit)
            self.path = []
            return
        }

        switch result {
        case .passed:
            status = .success
        case .failed:
            status = .failure
        case .skipped:
            status = .skipped
        case .expectedFailure:
            status = .expectedFailure
        }

        let durationSeconds = testCase.durationInSeconds ?? 0.0
        self.duration = .init(value: durationSeconds * 1000, unit: Self.defaultDurationUnit)

        self.path = []
    }

    enum Error: Swift.Error {
        case invalidNodeType
        case missingResult
    }

    static let defaultDurationUnit = UnitDuration.milliseconds
}

extension Array where Element: Equatable {
    var elementsAreEqual: Bool {
        dropFirst().allSatisfy { $0 == first }
    }
}

extension Set where Element == Report.Module.File {
    subscript(_ name: String) -> Element? {
        first { $0.name == name }
    }
}

extension Set where Element == Report.Module.File.RepeatableTest {
    subscript(_ name: String) -> Element? {
        first { $0.name == name }
    }
}

extension Set where Element == Report.Module {
    subscript(_ name: String) -> Element? {
        first { $0.name == name }
    }
}

extension Array where Element == Report.Module.File.RepeatableTest {
    public var totalDuration: Measurement<UnitDuration> {
        assert(map { $0.totalDuration.unit }.elementsAreEqual)
        let value = map { $0.totalDuration.value }.sum()
        let unit =
            first?.totalDuration.unit
            ?? Report.Module.File.RepeatableTest.Test.defaultDurationUnit
        return .init(value: value, unit: unit)
    }
}

extension Report.Module.File.RepeatableTest.Test.Status {
    public var icon: String {
        switch self {
        case .success:
            return "✅"
        case .failure:
            return "❌"
        case .skipped:
            return "⏭️"
        case .mixed:
            return "⚠️"
        case .expectedFailure:
            return "🤡"
        case .unknown:
            return "🤷"
        }
    }
}
