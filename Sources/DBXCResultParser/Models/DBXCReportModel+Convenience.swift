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
        let testResultsDTO = try await TestResultsDTO(from: xcresultPath)

        // Attempt to parse the code coverage data from the xcresult file, excluding specified targets.
        let coverageDTOs = try? await [CoverageDTO](from: xcresultPath)
            .filter { !excludingCoverageNames.contains($0.name) }

        let coverages = coverageDTOs?.map { Module.Coverage(from: $0) }

        var modules = Set<Module>()

        // Process test nodes: Test Plan -> Unit test bundle -> Test Suite -> Test Case -> Repetition
        for rootNode in testResultsDTO.testNodes {
            // Root node is "Test Plan", process its children (Unit test bundles)
            guard rootNode.nodeType == .testPlan, let unitTestBundles = rootNode.children else {
                continue
            }

            for testNode in unitTestBundles {
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
                        // Check if children are repetitions or direct messages (for skipped/expectedFailure)
                        let repetitions =
                            testCase.children?.filter { $0.nodeType == .repetition } ?? []
                        let directMessages =
                            testCase.children?.filter { $0.nodeType == .failureMessage } ?? []

                        if !repetitions.isEmpty {
                            // Has repetitions (multiple runs)
                            for repetition in repetitions {
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
                            // For skipped/expectedFailure, message might be in direct children
                            // For failed tests without repetitions, check testCase's failureMessage
                            let message: String?
                            if !directMessages.isEmpty {
                                // Extract message from direct children (for skipped/expectedFailure)
                                let rawMessage = directMessages.first?.name ?? ""
                                // Extract message after separator if present
                                if let skippedRange = rawMessage.range(of: "skipped -") {
                                    message = String(rawMessage[skippedRange.upperBound...])
                                        .trimmingCharacters(in: .whitespaces)
                                } else {
                                    message = rawMessage
                                }
                            } else {
                                message = testCase.failureMessage ?? testCase.skipMessage
                            }
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
        }

        self.modules = modules
    }
}
