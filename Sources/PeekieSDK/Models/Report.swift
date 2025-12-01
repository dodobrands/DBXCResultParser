import Foundation

public struct Report {
    public let modules: Set<Module>
    public let coverage: Double?

    /// All warnings from all modules in this report
    public var warnings: [Module.Suite.Issue] {
        modules.flatMap { $0.warnings }
    }
}

extension Report {
    public struct Module: Hashable {
        public let name: String
        public internal(set) var suites: Set<Suite>
        public let coverage: Coverage?

        public func hash(into hasher: inout Hasher) {
            hasher.combine(name)
        }

        public static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.name == rhs.name
        }

        /// All warnings from all suites in this module
        public var warnings: [Suite.Issue] {
            suites.flatMap { $0.warnings }
        }
    }

    public struct Coverage: Equatable {
        public let coveredLines: Int
        public let totalLines: Int
        public let coverage: Double
    }
}

extension Report.Module.Suite {
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
    public struct Suite: Hashable {
        public let name: String
        /// URL identifier from the test node in xcresult JSON.
        /// Examples:
        /// - Test Suite: `"test://com.apple.xcode/Module/ModuleTests/SuiteTests"`
        /// - Test Case: `"test://com.apple.xcode/Module/ModuleTests/SuiteTests/test_example"`
        /// - Unit test bundle: `"test://com.apple.xcode/Module/ModuleTests"`
        /// Format: `test://com.apple.xcode/<Module>/<Bundle>/<Suite>/<TestCase>`
        public let nodeIdentifierURL: String
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

extension Report.Module.Suite {
    public struct Issue: Equatable, Sendable {
        public let type: IssueType
        public let message: String

        public enum IssueType: String, Equatable, Sendable {
            case buildWarning = "Swift Compiler Warning"
        }
    }
}

extension Report.Module.Suite {
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

extension Report.Module.Suite.RepeatableTest {
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
        public let failureMessage: String?
        public let skipMessage: String?

        public init(
            name: String,
            status: Status,
            duration: Measurement<UnitDuration>,
            path: [PathNode],
            failureMessage: String? = nil,
            skipMessage: String? = nil
        ) {
            self.name = name
            self.status = status
            self.duration = duration
            self.path = path
            self.failureMessage = failureMessage
            self.skipMessage = skipMessage
        }

        /// Returns the appropriate message based on test status
        /// - For failures: returns failureMessage
        /// - For expected failures: returns failureMessage or "Failure is expected"
        /// - For skipped: returns skipMessage
        /// - For mixed: returns failureMessage
        /// - For other statuses: returns nil
        public var message: String? {
            switch status {
            case .failure:
                return failureMessage
            case .expectedFailure:
                return failureMessage ?? "Failure is expected"
            case .skipped:
                return skipMessage
            case .mixed:
                return failureMessage
            default:
                return nil
            }
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
    /// - Parameter filterDevice: If true, device nodes are filtered from the path. Defaults to false.
    /// - Returns: Array of merged tests
    public func mergedTests(filterDevice: Bool = false) -> [Test] {
        guard !tests.isEmpty else { return [] }

        // Group tests by path without repetition (and optionally device) elements
        var pathToTests: [String: [Test]] = [:]

        for test in tests {
            // Remove repetition nodes (always) and device nodes (if filterDevice is true) for grouping
            let pathForGrouping = test.path.filter {
                if $0.type == .repetition {
                    return false
                }
                if filterDevice && $0.type == .device {
                    return false
                }
                return true
            }
            let pathKey = self.pathKey(from: pathForGrouping)

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
            // Remove repetition nodes (always) and device nodes (if filterDevice is true) from path
            let firstTest = groupTests[0]
            let pathForResult = firstTest.path.filter {
                if $0.type == .repetition {
                    return false
                }
                if filterDevice && $0.type == .device {
                    return false
                }
                return true
            }

            // Build name: RepeatableTest name + names of all path elements in brackets
            let pathElementNames = pathForResult.map { $0.name }
            let mergedName: String
            if pathElementNames.isEmpty {
                mergedName = self.name
            } else {
                mergedName = "\(self.name) [\(pathElementNames.joined(separator: ", "))]"
            }

            // Check if statuses differ
            let statuses = groupTests.map { $0.status }
            let statusesDiffer = !statuses.elementsAreEqual

            let parentNode = pathForResult.last
            let status: Test.Status
            if statusesDiffer {
                status = .mixed
            } else {
                status = parentNode?.result ?? statuses.first ?? .unknown
            }

            // Sum durations of all tests in the group (all attempts)
            let totalDuration = groupTests.map { $0.duration.value }.sum()
            let duration = Measurement(value: totalDuration, unit: Test.defaultDurationUnit)

            // Extract messages from merged tests
            // For failures, prefer message from failed test, otherwise use first available
            let failureMessage: String? = {
                if status == .failure || status == .mixed {
                    return groupTests.first(where: { $0.status == .failure })?.failureMessage
                        ?? groupTests.first?.failureMessage
                }
                return nil
            }()

            // For skipped, prefer message from skipped test
            let skipMessage: String? = {
                if status == .skipped {
                    return groupTests.first(where: { $0.status == .skipped })?.skipMessage
                        ?? groupTests.first?.skipMessage
                }
                return nil
            }()

            mergedResults.append(
                Test(
                    name: mergedName,
                    status: status,
                    duration: duration,
                    path: pathForResult,
                    failureMessage: failureMessage,
                    skipMessage: skipMessage
                ))
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

extension Report.Module.Suite.RepeatableTest.Test {
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

extension Set where Element == Report.Module.Suite.RepeatableTest {
    /// Filters tests based on statis
    /// - Parameter testResults: statuses to leave in result
    /// - Returns: set of elements matching any of the specified statuses
    public func filtered(testResults: [Report.Module.Suite.RepeatableTest.Test.Status])
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

extension Report.Module.Suite.RepeatableTest.Test {
    /// Initializes from TestResultsDTO.TestNode (Repetition node) with path
    init(
        from node: TestResultsDTO.TestNode,
        path: [Report.Module.Suite.RepeatableTest.PathNode],
        testCaseName: String,
        testCase: TestResultsDTO.TestNode? = nil
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

        // Extract messages from repetition node itself (failure messages are in repetition children)
        // Fallback to testCase if repetition doesn't have messages (e.g., for expected failures)
        self.failureMessage = node.failureMessage ?? testCase?.failureMessage
        self.skipMessage = node.skipMessage ?? testCase?.skipMessage
    }

    /// Initializes from TestResultsDTO.TestNode (Arguments node) with path
    init(
        from node: TestResultsDTO.TestNode,
        path: [Report.Module.Suite.RepeatableTest.PathNode],
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
                self.failureMessage = nil
                self.skipMessage = nil
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

        // Extract messages from testCase metadata
        self.failureMessage = testCase.failureMessage
        self.skipMessage = testCase.skipMessage
    }

    /// Initializes from TestResultsDTO.TestNode (Test Case node) with empty path
    init(from testCase: TestResultsDTO.TestNode) {
        self.name = testCase.name

        guard let result = testCase.result else {
            self.status = .unknown
            self.duration = .init(value: 0, unit: Self.defaultDurationUnit)
            self.path = []
            self.failureMessage = nil
            self.skipMessage = nil
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

        // Extract messages from testCase metadata
        self.failureMessage = testCase.failureMessage
        self.skipMessage = testCase.skipMessage
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

extension Set where Element == Report.Module.Suite {
    subscript(_ name: String) -> Element? {
        first { $0.name == name }
    }
}

extension Set where Element == Report.Module.Suite.RepeatableTest {
    subscript(_ name: String) -> Element? {
        first { $0.name == name }
    }
}

extension Set where Element == Report.Module {
    subscript(_ name: String) -> Element? {
        first { $0.name == name }
    }
}

extension Array where Element == Report.Module.Suite.RepeatableTest {
    public var totalDuration: Measurement<UnitDuration> {
        assert(map { $0.totalDuration.unit }.elementsAreEqual)
        let value = map { $0.totalDuration.value }.sum()
        let unit =
            first?.totalDuration.unit
            ?? Report.Module.Suite.RepeatableTest.Test.defaultDurationUnit
        return .init(value: value, unit: unit)
    }
}

extension Report.Module.Suite.RepeatableTest.Test.Status {
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
