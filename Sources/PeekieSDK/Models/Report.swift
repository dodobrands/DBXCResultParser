import Foundation

public struct Report {
    public let modules: Set<Module>
    public let coverage: Double?
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
    }

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
        public internal(set) var warnings: [Warning]
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
    public struct Warning: Equatable {
        public let issueType: IssueType
        public let message: String

        public enum IssueType: String, Equatable {
            case buildWarning
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
    public struct Test {
        public let status: Status
        public let duration: Measurement<UnitDuration>
        public let message: String?
    }

    public var combinedStatus: Test.Status {
        let statuses = tests.map { $0.status }
        if statuses.elementsAreEqual {
            return statuses.first ?? .success
        } else {
            return .mixed
        }
    }

    public var message: String? {
        tests.first?.message
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
    /// Initializes from TestResultsDTO.TestNode (Repetition node)
    init(from repetitionNode: TestResultsDTO.TestNode) throws {
        guard repetitionNode.nodeType == .repetition else {
            throw Error.invalidNodeType
        }

        guard let result = repetitionNode.result else {
            throw Error.missingResult
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

        let durationSeconds = repetitionNode.durationInSeconds ?? 0.0
        self.duration = .init(value: durationSeconds * 1000, unit: Self.defaultDurationUnit)

        // Extract message from failure message children
        self.message = repetitionNode.failureMessage ?? repetitionNode.skipMessage
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
