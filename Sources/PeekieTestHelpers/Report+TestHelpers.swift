import Foundation

@testable import PeekieSDK

extension Report {
    public static func testMake(
        modules: Set<Module> = [],
        coverage: Double? = nil
    ) -> Self {
        // Calculate coverage from files if not provided
        let calculatedCoverage: Double?
        if let coverage = coverage {
            calculatedCoverage = coverage
        } else {
            let fileCoverages = modules.flatMap { $0.files }.compactMap { $0.coverage }
            if fileCoverages.count > 0 {
                let totalLines = fileCoverages.reduce(into: 0) { $0 += $1.totalLines }
                let totalCoveredLines = fileCoverages.reduce(into: 0) { $0 += $1.coveredLines }
                if totalLines != 0 {
                    calculatedCoverage = Double(totalCoveredLines) / Double(totalLines)
                } else {
                    calculatedCoverage = 0.0
                }
            } else {
                calculatedCoverage = nil
            }
        }
        return .init(
            modules: modules,
            coverage: calculatedCoverage
        )
    }
}

extension Report.Module {
    public static func testMake(
        name: String = "",
        files: Set<File> = [],
        coverage: Report.Coverage? = nil
    ) -> Self {
        .init(name: name, files: files, coverage: coverage)
    }
}

extension Report.Module.File.Coverage {
    public static func testMake(
        coveredLines: Int = 0,
        totalLines: Int = 0,
        coverage: Double = 0.0
    ) -> Self {
        Self(
            coveredLines: coveredLines,
            totalLines: totalLines,
            coverage: coverage)
    }
}

extension Report.Module.File {
    public static func testMake(
        name: String = "",
        repeatableTests: Set<RepeatableTest> = [],
        coverage: Coverage? = nil
    ) -> Self {
        .init(name: name, repeatableTests: repeatableTests, coverage: coverage)
    }
}

extension Report.Module.File.RepeatableTest {
    public static func testMake(
        name: String = "",
        tests: [Test] = []
    ) -> Self {
        .init(name: name, tests: tests)
    }

    public static func failed(
        named name: String,
        times: Int = 1,
        message: String? = nil
    ) -> Self {
        let tests = Array(
            repeating: Report.Module.File.RepeatableTest.Test.testMake(
                status: .failure, message: message),
            count: times
        )
        return .testMake(name: name, tests: tests)
    }

    public static func succeeded(
        named name: String
    ) -> Self {
        .testMake(name: name, tests: [.testMake(status: .success)])
    }

    public static func skipped(
        named name: String,
        message: String? = nil
    ) -> Self {
        .testMake(name: name, tests: [.testMake(status: .skipped, message: message)])
    }

    public static func expectedFailed(
        named name: String,
        message: String? = nil
    ) -> Self {
        .testMake(name: name, tests: [.testMake(status: .expectedFailure, message: message)])
    }

    public static func mixedFailedSucceeded(
        named name: String,
        failedTimes: Int = 1
    ) -> Self {
        let failedTests = Array(
            repeating: Report.Module.File.RepeatableTest.Test.testMake(status: .failure),
            count: failedTimes
        )
        return .testMake(name: name, tests: failedTests + [.testMake(status: .success)])
    }
}

extension Report.Module.File.RepeatableTest.Test {
    public static func testMake(
        status: Status = .success,
        duration: Measurement<UnitDuration> = .testMake(),
        message: String? = nil
    ) -> Self {
        .init(
            status: status,
            duration: duration,
            message: message
        )
    }
}
