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

        // Try to get total coverage from xcresult file
        let totalCoverageDTO = try? await TotalCoverageDTO(from: xcresultPath)

        // Try to get build results (warnings, errors) from xcresult file
        // Note: build-results may not be available in test-only xcresult files
        let buildResultsDTO: BuildResultsDTO?
        do {
            buildResultsDTO = try await BuildResultsDTO(from: xcresultPath)
        } catch {
            // Build results not available (e.g., test-only xcresult), continue without warnings
            buildResultsDTO = nil
        }
        let warnings = buildResultsDTO?.warnings.map { Warning(from: $0) } ?? []

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

                        if !repetitions.isEmpty {
                            // Has repetitions (multiple runs)
                            for repetition in repetitions {
                                let test = try DBXCReportModel.Module.File.RepeatableTest.Test(
                                    from: repetition)
                                repeatableTest.tests.append(test)
                            }
                        } else {
                            // No repetitions, check if we have Arguments nodes in Device children
                            // Extract all Arguments from Device nodes
                            let argumentsFromDevices =
                                testCase.children?
                                .flatMap { node -> [(String, TestResultsDTO.TestNode.Result?)] in
                                    if node.nodeType == .device {
                                        // Extract Arguments with their results from Device children
                                        return node.children?
                                            .filter { $0.nodeType == .arguments }
                                            .map { ($0.name, $0.result) } ?? []
                                    } else if node.nodeType == .arguments {
                                        // Direct Arguments node
                                        return [(node.name, node.result)]
                                    }
                                    return []
                                } ?? []

                            if !argumentsFromDevices.isEmpty {
                                // Create separate test for each argument with its own status
                                let baseDurationSeconds = testCase.durationInSeconds ?? 0.0
                                for (argumentName, argumentResult) in argumentsFromDevices {
                                    let status:
                                        DBXCReportModel.Module.File.RepeatableTest.Test.Status
                                    if let result = argumentResult {
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
                                        // Fallback to test case result if argument doesn't have result
                                        guard let testCaseResult = testCase.result else { continue }
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

                                    // Extract message based on test status
                                    let message: String?
                                    switch status {
                                    case .skipped:
                                        message = testCase.skipMessage ?? argumentName
                                    case .failure:
                                        message = testCase.failureMessage ?? argumentName
                                    case .expectedFailure:
                                        message = testCase.failureMessage ?? argumentName
                                    default:
                                        message = argumentName
                                    }

                                    let duration = Measurement<UnitDuration>(
                                        value: baseDurationSeconds * 1000,
                                        unit: DBXCReportModel.Module.File.RepeatableTest.Test
                                            .defaultDurationUnit
                                    )

                                    let test = DBXCReportModel.Module.File.RepeatableTest.Test(
                                        status: status,
                                        duration: duration,
                                        message: message
                                    )
                                    repeatableTest.tests.append(test)
                                }
                            } else {
                                // No arguments, treat test case as single test
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
                                // Extract message based on test status
                                let message: String?
                                switch status {
                                case .skipped:
                                    message = testCase.skipMessage
                                case .failure:
                                    message = testCase.failureMessage
                                case .expectedFailure:
                                    message = testCase.failureMessage
                                default:
                                    // Fallback to first non-metadata child name
                                    message =
                                        testCase.children?
                                        .first(where: {
                                            $0.nodeType != .device && $0.nodeType != .runtimeWarning
                                        })?
                                        .name
                                }
                                let test = DBXCReportModel.Module.File.RepeatableTest.Test(
                                    status: status,
                                    duration: duration,
                                    message: message
                                )
                                repeatableTest.tests.append(test)
                            }
                        }

                        file.repeatableTests.update(with: repeatableTest)
                    }

                    module.files.update(with: file)
                }

                modules.update(with: module)
            }
        }

        // Use total coverage from xcresult file if available, otherwise calculate from modules
        let totalCoverage: Double?
        if let totalCoverageDTO = totalCoverageDTO {
            // Use the lineCoverage from xcresult file (already calculated)
            totalCoverage = totalCoverageDTO.lineCoverage
        } else {
            // Fallback: calculate from modules
            let moduleCoverages = modules.map { $0.coverage }.compactMap { $0 }
            if moduleCoverages.count > 0 {
                let totalLines = moduleCoverages.reduce(into: 0) { $0 += $1.totalLines }
                let totalCoveredLines = moduleCoverages.reduce(into: 0) { $0 += $1.coveredLines }
                if totalLines != 0 {
                    totalCoverage = Double(totalCoveredLines) / Double(totalLines)
                } else {
                    totalCoverage = 0.0
                }
            } else {
                totalCoverage = nil
            }
        }

        self.modules = modules
        self.coverage = totalCoverage
        self.warnings = warnings
    }
}

extension DBXCReportModel.Warning {
    init(from issue: BuildResultsDTO.Issue) {
        self.message = issue.message
        self.sourceURL = issue.sourceURL
        self.className = issue.className
    }
}
