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
        let buildResultsDTO = try await BuildResultsDTO(from: xcresultPath)
        let coverageReportDTO = try await CoverageReportDTO(from: xcresultPath)

        // Build a map of file paths to coverage data
        var fileCoverageMap: [String: FileCoverageDTO] = [:]
        for target in coverageReportDTO.targets {
            guard !excludingCoverageNames.contains(target.name) else { continue }
            for fileCoverage in target.files {
                // Use both path and name as keys for matching
                let path = fileCoverage.path
                let name = fileCoverage.name
                fileCoverageMap[path] = fileCoverage
                fileCoverageMap[name] = fileCoverage
            }
        }

        // Parse warnings from build results
        let warningsByFileName = Self.parseWarnings(from: buildResultsDTO)

        // Try to get total coverage from xcresult file
        let totalCoverageDTO = try await TotalCoverageDTO(from: xcresultPath)

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

                // Find coverage files for this module
                // Coverage is organized by target (source module), not test module
                // We need to find all coverage files that belong to this test module's source
                var moduleCoverageFiles: [String: FileCoverageDTO] = [:]
                var matchedTargetCoverage: Report.Coverage? = nil
                for target in coverageReportDTO.targets {
                    guard !excludingCoverageNames.contains(target.name) else { continue }
                    // Try to match target name with module name
                    // Module name is like "DBXCResultParserTests", target might be "DBXCResultParser"
                    let targetBaseName = target.name.replacingOccurrences(of: "Tests", with: "")
                    let moduleBaseName = moduleName.replacingOccurrences(of: "Tests", with: "")

                    if target.name == moduleName || targetBaseName == moduleBaseName
                        || moduleName.contains(target.name)
                        || target.name.contains(moduleBaseName)
                    {
                        // Store target-level coverage
                        if target.executableLines > 0 {
                            matchedTargetCoverage = Report.Coverage(
                                coveredLines: target.coveredLines,
                                totalLines: target.executableLines,
                                coverage: target.lineCoverage
                            )
                        }

                        for fileCoverage in target.files {
                            // Use file name (without path) as key
                            moduleCoverageFiles[fileCoverage.name] = fileCoverage
                            // Also use path as key for matching
                            moduleCoverageFiles[fileCoverage.path] = fileCoverage
                        }
                    }
                }

                var module =
                    modules[moduleName]
                    ?? Report.Module(
                        name: moduleName,
                        files: [],
                        coverage: matchedTargetCoverage
                    )

                // Process test suites (files)
                guard let testSuites = testNode.children else { continue }
                for testSuite in testSuites {
                    guard testSuite.nodeType == .testSuite else { continue }

                    // Extract file name from test suite name (e.g., "ReportTests")
                    let fileName = testSuite.name

                    // Try to find coverage for this file by name or path
                    let fileCoverage: Report.Module.File.Coverage? = {
                        // First try by exact file name
                        if let coverageDTO = fileCoverageMap[fileName] {
                            return Report.Module.File.Coverage(from: coverageDTO)
                        }
                        // Try with .swift extension
                        let fileNameWithExtension = fileName + ".swift"
                        if let coverageDTO = fileCoverageMap[fileNameWithExtension] {
                            return Report.Module.File.Coverage(from: coverageDTO)
                        }
                        // Try to match by extracting base name from test suite
                        // Test suite names might be like "ReportTests" but file might be "Report.swift"
                        let baseName = fileName.replacingOccurrences(of: "Tests", with: "")
                        let possibleNames = [
                            baseName + ".swift",
                            baseName,
                        ]
                        for possibleName in possibleNames {
                            if let coverageDTO = fileCoverageMap[possibleName] {
                                return Report.Module.File.Coverage(from: coverageDTO)
                            }
                        }
                        // Try to find in module-specific coverage files
                        for (key, coverageDTO) in moduleCoverageFiles {
                            // Match by exact key or by comparing names (with/without .swift)
                            let coverageNameWithoutExt =
                                coverageDTO.name.hasSuffix(".swift")
                                ? String(coverageDTO.name.dropLast(6))
                                : coverageDTO.name
                            if key == fileName
                                || key == fileName + ".swift"
                                || key.contains(fileName)
                                || fileName == coverageNameWithoutExt
                                || fileName == coverageDTO.name
                            {
                                return Report.Module.File.Coverage(from: coverageDTO)
                            }
                        }
                        // Try to find by matching file name in path
                        for (path, coverageDTO) in fileCoverageMap {
                            // Match by exact path or by comparing names (with/without .swift)
                            let coverageNameWithoutExt =
                                coverageDTO.name.hasSuffix(".swift")
                                ? String(coverageDTO.name.dropLast(6))
                                : coverageDTO.name
                            if path == fileName
                                || path == fileName + ".swift"
                                || path.contains(fileName)
                                || fileName == coverageNameWithoutExt
                                || fileName == coverageDTO.name
                            {
                                return Report.Module.File.Coverage(from: coverageDTO)
                            }
                        }
                        return nil
                    }()

                    var file =
                        module.files[fileName]
                        ?? .init(
                            name: fileName,
                            repeatableTests: [],
                            warnings: Self.warningsFor(fileName: fileName, in: warningsByFileName),
                            coverage: fileCoverage
                        )

                    let fileWarnings = Self.warningsFor(fileName: fileName, in: warningsByFileName)
                    if !fileWarnings.isEmpty {
                        file.warnings = Self.mergeWarnings(file.warnings, fileWarnings)
                    }

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

                // Update module in set, preserving coverage
                if let existingModule = modules[moduleName] {
                    modules.remove(existingModule)
                }
                modules.insert(module)
            }
        }

        // Add all files with coverage to modules, even if they don't have test files
        for target in coverageReportDTO.targets {
            guard !excludingCoverageNames.contains(target.name) else { continue }

            // Create coverage from target-level data if available
            let targetCoverage: Report.Coverage? = {
                guard target.executableLines > 0 else { return nil }
                return Report.Coverage(
                    coveredLines: target.coveredLines,
                    totalLines: target.executableLines,
                    coverage: target.lineCoverage
                )
            }()

            // Try to find existing module by target name or create a new one
            // Target name might be like "DBXCResultParser", module might be "DBXCResultParserTests"
            var moduleName = target.name
            var existingModule = modules[moduleName]

            // If not found, try to find module with "Tests" suffix
            if existingModule == nil {
                let moduleNameWithTests = target.name + "Tests"
                if let foundModule = modules[moduleNameWithTests] {
                    existingModule = foundModule
                    moduleName = moduleNameWithTests
                }
            }

            // Start with existing module files or empty set
            var moduleFiles = existingModule?.files ?? Set<Report.Module.File>()

            // Determine module coverage: use target coverage if module doesn't have one, or keep existing
            let moduleCoverage = existingModule?.coverage ?? targetCoverage

            // Add all coverage files to this module
            for fileCoverageDTO in target.files {
                let coverage = Report.Module.File.Coverage(from: fileCoverageDTO)
                // Use the name as it appears in xcresult
                // If name contains path separators, extract just the filename
                var fileName = fileCoverageDTO.name
                if let lastSlash = fileName.lastIndex(of: "/") {
                    fileName = String(fileName[fileName.index(after: lastSlash)...])
                }

                // Check if file already exists in module (from test suites)
                if let existingFile = moduleFiles[fileName] {
                    // File exists - update coverage if it doesn't have one
                    if existingFile.coverage == nil {
                        let updatedFile = Report.Module.File(
                            name: fileName,
                            repeatableTests: existingFile.repeatableTests,
                            warnings: Self.mergeWarnings(
                                existingFile.warnings,
                                Self.warningsFor(fileName: fileName, in: warningsByFileName)
                            ),
                            coverage: coverage
                        )
                        moduleFiles.remove(existingFile)
                        moduleFiles.insert(updatedFile)
                    }
                    // If file already has coverage, keep existing one (from test suite matching)
                } else {
                    // Create new file entry with coverage but no tests
                    let newFile = Report.Module.File(
                        name: fileName,
                        repeatableTests: [],
                        warnings: Self.warningsFor(fileName: fileName, in: warningsByFileName),
                        coverage: coverage
                    )
                    moduleFiles.insert(newFile)
                }
            }

            // Remove old module if it existed and add updated one
            if let oldModule = existingModule {
                modules.remove(oldModule)
            }

            // Create or update module with all files and coverage
            let updatedModule = Report.Module(
                name: moduleName, files: moduleFiles, coverage: moduleCoverage)
            modules.insert(updatedModule)
        }

        // Use total coverage from xcresult file if available, otherwise calculate from files
        let totalCoverage: Double? = {
            let lineCoverage = totalCoverageDTO.lineCoverage
            // totalCoverageDTO is available; still allow fallback in case of zeroed data
            if lineCoverage > 0 {
                return lineCoverage
            }

            let fileCoverages = modules.flatMap { $0.files }.compactMap { $0.coverage }
            guard !fileCoverages.isEmpty else { return nil }
            let totalLines = fileCoverages.reduce(0) { $0 + $1.totalLines }
            let totalCoveredLines = fileCoverages.reduce(0) { $0 + $1.coveredLines }
            return totalLines != 0 ? Double(totalCoveredLines) / Double(totalLines) : 0.0
        }()

        self.modules = modules
        self.coverage = totalCoverage
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
