//
//  DBXCReportModel+Convenience.swift
//
//
//  Created by Aleksey Berezka on 15.12.2023.
//

import Foundation

extension DBXCReportModel {
    /// Initializes a new instance of the `DBXCReportModel` using the provided `xcresultPath`.
    /// The initialization process involves parsing the `.xcresult` file to extract various reports.
    /// Coverage data for targets specified in `excludingCoverageNames` will be excluded from the report.
    ///
    /// - Parameters:
    ///   - xcresultPath: The file URL of the `.xcresult` file to parse.
    ///   - excludingCoverageNames: An array of strings representing the names of the targets to be excluded
    ///                             from the code coverage report. Defaults to an empty array, meaning no
    ///                             targets will be excluded.
    /// - Throws: An error if the `.xcresult` file cannot be parsed.
    public init(
        xcresultPath: URL,
        excludingCoverageNames: [String] = []
    ) async throws {
        // Use new format API (without --legacy flag)
        try await self.init(
            fromNewFormat: xcresultPath, excludingCoverageNames: excludingCoverageNames)
    }

    /// Initializes a new instance using the new test-results API format (without --legacy flag)
    /// This is an alternative initializer that uses the new xcresulttool API
    public init(
        fromNewFormat xcresultPath: URL,
        excludingCoverageNames: [String] = []
    ) async throws {
        let testResultsDTO = try await TestResultsDTO(from: xcresultPath)

        // Attempt to parse the code coverage data from the xcresult file, excluding specified targets.
        let coverageDTOs = try? await [CoverageDTO](from: xcresultPath)
            .filter { !excludingCoverageNames.contains($0.name) }

        // TODO: Get warningCount from build-results or test-results summary
        self.warningCount = nil

        let coverages = coverageDTOs?.map { Module.Coverage(from: $0) }

        var modules = Set<Module>()

        // Process test nodes: Unit test bundle -> Test Suite -> Test Case -> Repetition
        for testNode in testResultsDTO.testNodes {
            guard testNode.nodeType == .unitTestBundle else { continue }

            // Extract module name from unit test bundle name (e.g., "DBXCResultParserTests")
            let moduleName = testNode.name

            var module =
                modules[moduleName]
                ?? DBXCReportModel.Module(
                    name: moduleName,
                    files: [],
                    coverage: coverages?.forModule(named: moduleName)
                )

            // Process test suites (files)
            guard let testSuites = testNode.children else { continue }
            for testSuite in testSuites {
                guard testSuite.nodeType == .testSuite else { continue }

                // Extract file name from test suite name (e.g., "DBXCReportModelTests")
                let fileName = testSuite.name
                var file =
                    module.files[fileName]
                    ?? .init(name: fileName, repeatableTests: [])

                // Process test cases
                guard let testCases = testSuite.children else { continue }
                for testCase in testCases {
                    guard testCase.nodeType == .testCase else { continue }

                    let testName = testCase.name
                    var repeatableTest =
                        file.repeatableTests[testName]
                        ?? DBXCReportModel.Module.File.RepeatableTest(
                            name: testName,
                            tests: []
                        )

                    // Process repetitions (individual test runs)
                    if let repetitions = testCase.children {
                        // Has repetitions (multiple runs)
                        for repetition in repetitions {
                            guard repetition.nodeType == .repetition else { continue }
                            let test = try DBXCReportModel.Module.File.RepeatableTest.Test(
                                from: repetition)
                            repeatableTest.tests.append(test)
                        }
                    } else {
                        // No repetitions, treat test case as single test
                        // Create a test from the test case itself
                        guard let result = testCase.result else { continue }
                        let status: DBXCReportModel.Module.File.RepeatableTest.Test.Status
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
                        let duration = Measurement<UnitDuration>(
                            value: durationSeconds * 1000,
                            unit: DBXCReportModel.Module.File.RepeatableTest.Test
                                .defaultDurationUnit
                        )
                        let message = testCase.failureMessage ?? testCase.skipMessage
                        let test = DBXCReportModel.Module.File.RepeatableTest.Test(
                            status: status,
                            duration: duration,
                            message: message
                        )
                        repeatableTest.tests.append(test)
                    }

                    file.repeatableTests.update(with: repeatableTest)
                }

                module.files.update(with: file)
            }

            modules.update(with: module)
        }

        self.modules = modules
    }
}
