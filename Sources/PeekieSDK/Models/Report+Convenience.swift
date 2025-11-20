import Foundation

extension Report {
    /// Initializes a new instance of the `Report` using the provided `xcresultPath`.
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
        let buildResultsDTO = try? await BuildResultsDTO(from: xcresultPath)
        // Filter warnings to include only those with required fields (sourceURL and className)
        let warnings = buildResultsDTO?.warnings.compactMap { Warning(from: $0) } ?? []

        var modules = Set<Module>()

        // Process test nodes: Test Plan -> Unit test bundle -> Test Suite -> Test Case -> Repetition
        for rootNode in testResultsDTO.testNodes {
            // Root node is "Test Plan", process its children (Unit test bundles)
            guard rootNode.nodeType == .testPlan, let unitTestBundles = rootNode.children else {
                continue
            }

            for testNode in unitTestBundles {
                guard testNode.nodeType == .unitTestBundle else { continue }

                // Extract module name from unit test bundle name (e.g., "PeekieTests")
                let moduleName = testNode.name

                var module =
                    modules[moduleName]
                    ?? Report.Module(
                        name: moduleName,
                        files: [],
                        coverage: coverages?.forModule(named: moduleName)
                    )

                // Process test suites (files)
                guard let testSuites = testNode.children else { continue }
                for testSuite in testSuites {
                    guard testSuite.nodeType == .testSuite else { continue }

                    // Extract file name from test suite name (e.g., "ReportTests")
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
                            ?? Report.Module.File.RepeatableTest(
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
                                let test = try Report.Module.File.RepeatableTest.Test(
                                    from: repetition)
                                repeatableTest.tests.append(test)
                            }
                        } else {
                            // No repetitions, check if we have Arguments nodes
                            // Extract all Arguments nodes
                            let arguments =
                                testCase.children?
                                .filter { $0.nodeType == .arguments }
                                .map { ($0.name, $0.result) } ?? []

                            if !arguments.isEmpty {
                                // Create separate test for each argument with its own status
                                let baseDurationSeconds = testCase.durationInSeconds ?? 0.0
                                for (argumentName, argumentResult) in arguments {
                                    let status: Report.Module.File.RepeatableTest.Test.Status
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
                                        message =
                                            testCase.skipMessage ?? argumentName.trimmingQuotes
                                    case .failure:
                                        message =
                                            testCase.failureMessage ?? argumentName.trimmingQuotes
                                    case .expectedFailure:
                                        message =
                                            testCase.failureMessage ?? argumentName.trimmingQuotes
                                    default:
                                        message = argumentName.trimmingQuotes
                                    }

                                    let duration = Measurement<UnitDuration>(
                                        value: baseDurationSeconds * 1000,
                                        unit: Report.Module.File.RepeatableTest.Test
                                            .defaultDurationUnit
                                    )

                                    let test = Report.Module.File.RepeatableTest.Test(
                                        status: status,
                                        duration: duration,
                                        message: message
                                    )
                                    repeatableTest.tests.append(test)
                                }
                            } else {
                                // No arguments, treat test case as single test
                                guard let result = testCase.result else { continue }
                                let status: Report.Module.File.RepeatableTest.Test.Status
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
                                    unit: Report.Module.File.RepeatableTest.Test
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
                                            $0.nodeType != .runtimeWarning
                                        })?
                                        .name
                                }
                                let test = Report.Module.File.RepeatableTest.Test(
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
        let totalCoverage =
            totalCoverageDTO?.lineCoverage
            ?? {
                let moduleCoverages = modules.compactMap { $0.coverage }
                guard !moduleCoverages.isEmpty else { return nil }
                let totalLines = moduleCoverages.reduce(0) { $0 + $1.totalLines }
                let totalCoveredLines = moduleCoverages.reduce(0) { $0 + $1.coveredLines }
                return totalLines != 0 ? Double(totalCoveredLines) / Double(totalLines) : 0.0
            }()

        self.modules = modules
        self.coverage = totalCoverage
        self.warnings = warnings
    }
}

extension Report.Warning {
    /// Creates a Warning from BuildResultsDTO.Issue, skipping if required fields are missing
    init?(from issue: BuildResultsDTO.Issue) {
        guard let sourceURL = issue.sourceURL, let className = issue.className else {
            // Skip warnings without required location information
            return nil
        }
        self.message = issue.message
        self.sourceURL = sourceURL
        self.className = className
    }
}

extension String {
    /// Removes surrounding quotes if present (both single and double quotes)
    var trimmingQuotes: String {
        var result = self
        // Remove double quotes
        if result.hasPrefix("\"") && result.hasSuffix("\"") {
            result = String(result.dropFirst().dropLast())
        }
        // Remove single quotes
        if result.hasPrefix("'") && result.hasSuffix("'") {
            result = String(result.dropFirst().dropLast())
        }
        return result
    }
}
