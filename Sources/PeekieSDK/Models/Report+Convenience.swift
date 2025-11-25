import Foundation

extension Report {
    /// Initializes a new instance of the `Report` using the provided `xcresultPath`.
    /// The initialization process involves parsing the `.xcresult` file to extract various reports.
    ///
    /// - Parameters:
    ///   - xcresultPath: The file URL of the `.xcresult` file to parse.
    ///   - includeCoverage: Whether to parse and include code coverage data. Defaults to `true`.
    ///   - includeWarnings: Whether to parse and include build warnings. Defaults to `true`.
    /// - Throws: An error if the `.xcresult` file cannot be parsed.
    public init(
        xcresultPath: URL,
        includeCoverage: Bool = true,
        includeWarnings: Bool = true
    ) async throws {
        let testResultsDTO = try await TestResultsDTO(from: xcresultPath)
        let buildResultsDTO: BuildResultsDTO? =
            includeWarnings ? try await BuildResultsDTO(from: xcresultPath) : nil
        let coverageReportDTO: CoverageReportDTO? =
            includeCoverage ? try await CoverageReportDTO(from: xcresultPath) : nil

        // Build a map of file paths to coverage data
        var fileCoverageMap: [String: FileCoverageDTO] = [:]
        if let coverageReportDTO = coverageReportDTO {
            for target in coverageReportDTO.targets {
                for fileCoverage in target.files {
                    // Use both path and name as keys for matching
                    let path = fileCoverage.path
                    let name = fileCoverage.name
                    fileCoverageMap[path] = fileCoverage
                    fileCoverageMap[name] = fileCoverage
                }
            }
        }

        // Parse warnings from build results
        let warningsByFileName: [String: [Report.Module.File.Issue]]
        if let buildResultsDTO = buildResultsDTO {
            warningsByFileName = await Self.parseWarnings(from: buildResultsDTO)
        } else {
            warningsByFileName = [:]
        }

        // Try to get total coverage from xcresult file
        let totalCoverageDTO: TotalCoverageDTO? =
            includeCoverage ? try? await TotalCoverageDTO(from: xcresultPath) : nil

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
                if let coverageReportDTO = coverageReportDTO {
                    for target in coverageReportDTO.targets {
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
                    let fileCoverage: Report.Module.File.Coverage?
                    if includeCoverage {
                        // First try by exact file name
                        if let coverageDTO = fileCoverageMap[fileName] {
                            fileCoverage = Report.Module.File.Coverage(from: coverageDTO)
                        } else {
                            // Try with .swift extension
                            let fileNameWithExtension = fileName + ".swift"
                            if let coverageDTO = fileCoverageMap[fileNameWithExtension] {
                                fileCoverage = Report.Module.File.Coverage(from: coverageDTO)
                            } else {
                                // Try to match by extracting base name from test suite
                                // Test suite names might be like "ReportTests" but file might be "Report.swift"
                                let baseName = fileName.replacingOccurrences(of: "Tests", with: "")
                                let possibleNames = [
                                    baseName + ".swift",
                                    baseName,
                                ]
                                var found: FileCoverageDTO? = nil
                                for possibleName in possibleNames {
                                    if let coverageDTO = fileCoverageMap[possibleName] {
                                        found = coverageDTO
                                        break
                                    }
                                }
                                if found == nil {
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
                                            found = coverageDTO
                                            break
                                        }
                                    }
                                }
                                if found == nil {
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
                                            found = coverageDTO
                                            break
                                        }
                                    }
                                }
                                fileCoverage = found.map { Report.Module.File.Coverage(from: $0) }
                            }
                        }
                    } else {
                        fileCoverage = nil
                    }

                    let fileWarnings: [Report.Module.File.Issue] =
                        includeWarnings
                        ? Self.warningsFor(fileName: fileName, in: warningsByFileName)
                        : []
                    var file =
                        module.files[fileName]
                        ?? .init(
                            name: fileName,
                            repeatableTests: [],
                            warnings: fileWarnings,
                            coverage: fileCoverage
                        )

                    if includeWarnings && !fileWarnings.isEmpty {
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

                        // Filter out metadata nodes from test case children
                        let filteredTestCaseChildren = (testCase.children ?? []).filter {
                            !$0.isMetadata
                        }

                        // Process test case children and create Test objects with paths
                        func processNode(
                            _ node: TestResultsDTO.TestNode,
                            path: [Report.Module.File.RepeatableTest.PathNode],
                            testCase: TestResultsDTO.TestNode
                        ) throws {
                            // Check if this node should be added to path
                            let pathNode: Report.Module.File.RepeatableTest.PathNode?
                            switch node.nodeType {
                            case .device, .arguments, .repetition:
                                // Convert result from DTO to Test.Status
                                let result: Report.Module.File.RepeatableTest.Test.Status? = {
                                    guard let dtoResult = node.result else { return nil }
                                    switch dtoResult {
                                    case .passed:
                                        return .success
                                    case .failed:
                                        return .failure
                                    case .skipped:
                                        return .skipped
                                    case .expectedFailure:
                                        return .expectedFailure
                                    }
                                }()

                                // Convert duration from DTO
                                let duration: Measurement<UnitDuration>? = {
                                    guard let durationSeconds = node.durationInSeconds else {
                                        return nil
                                    }
                                    return .init(
                                        value: durationSeconds * 1000,
                                        unit: Report.Module.File.RepeatableTest.Test
                                            .defaultDurationUnit
                                    )
                                }()

                                // Extract message from DTO
                                let message = node.failureMessage ?? node.skipMessage

                                pathNode = Report.Module.File.RepeatableTest.PathNode(
                                    name: node.name,
                                    type: .init(from: node.nodeType),
                                    result: result,
                                    duration: duration,
                                    message: message
                                )
                            default:
                                pathNode = nil
                            }

                            var newPath = path
                            if let pathNode = pathNode {
                                newPath.append(pathNode)
                            }

                            // If this is a repetition node, create test and stop recursion
                            if node.nodeType == .repetition {
                                let test = try Report.Module.File.RepeatableTest.Test(
                                    from: node,
                                    path: newPath,
                                    testCaseName: testCase.name,
                                    testCase: testCase
                                )
                                repeatableTest.tests.append(test)
                                return
                            }

                            guard let nodeChildren = node.children else {
                                // Leaf node - create test if it's an arguments node without children
                                if node.nodeType == .arguments {
                                    let test = Report.Module.File.RepeatableTest.Test(
                                        from: node,
                                        path: newPath,
                                        testCase: testCase
                                    )
                                    repeatableTest.tests.append(test)
                                }
                                return
                            }

                            // Filter out metadata nodes from node children
                            let filteredNodeChildren = nodeChildren.filter { !$0.isMetadata }

                            // If this is an arguments node, check if it has repetitions
                            if node.nodeType == .arguments {
                                let hasRepetitions = filteredNodeChildren.contains {
                                    $0.nodeType == .repetition
                                }
                                if !hasRepetitions {
                                    // Arguments without repetitions - create test and stop recursion
                                    let test = Report.Module.File.RepeatableTest.Test(
                                        from: node,
                                        path: newPath,
                                        testCase: testCase
                                    )
                                    repeatableTest.tests.append(test)
                                    return
                                }
                                // Arguments with repetitions - continue recursion to process repetitions
                            }

                            // Recursively process children (already filtered)
                            for child in filteredNodeChildren {
                                try processNode(child, path: newPath, testCase: testCase)
                            }
                        }

                        // Start processing from filtered test case children
                        for child in filteredTestCaseChildren {
                            try processNode(child, path: [], testCase: testCase)
                        }

                        // If no tests were created (no children or only metadata), create test from test case itself
                        assert(
                            !repeatableTest.tests.isEmpty || filteredTestCaseChildren.isEmpty,
                            "Tests are empty but test case has non-empty filtered children. This indicates a parsing issue."
                        )
                        if repeatableTest.tests.isEmpty {
                            let test = Report.Module.File.RepeatableTest.Test(from: testCase)
                            repeatableTest.tests.append(test)
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
        if let coverageReportDTO = coverageReportDTO {
            for target in coverageReportDTO.targets {
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
                            let updatedWarnings: [Report.Module.File.Issue] =
                                includeWarnings
                                ? Self.mergeWarnings(
                                    existingFile.warnings,
                                    Self.warningsFor(fileName: fileName, in: warningsByFileName)
                                )
                                : existingFile.warnings
                            let updatedFile = Report.Module.File(
                                name: fileName,
                                repeatableTests: existingFile.repeatableTests,
                                warnings: updatedWarnings,
                                coverage: coverage
                            )
                            moduleFiles.remove(existingFile)
                            moduleFiles.insert(updatedFile)
                        }
                        // If file already has coverage, keep existing one (from test suite matching)
                    } else {
                        // Create new file entry with coverage but no tests
                        let newFileWarnings: [Report.Module.File.Issue] =
                            includeWarnings
                            ? Self.warningsFor(fileName: fileName, in: warningsByFileName)
                            : []
                        let newFile = Report.Module.File(
                            name: fileName,
                            repeatableTests: [],
                            warnings: newFileWarnings,
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
        }

        // Use total coverage from xcresult file if available, otherwise calculate from files
        let totalCoverage: Double? =
            includeCoverage
            ? {
                if let totalCoverageDTO = totalCoverageDTO {
                    let lineCoverage = totalCoverageDTO.lineCoverage
                    // totalCoverageDTO is available; still allow fallback in case of zeroed data
                    if lineCoverage > 0 {
                        return lineCoverage
                    }
                }

                let fileCoverages = modules.flatMap { $0.files }.compactMap { $0.coverage }
                guard !fileCoverages.isEmpty else { return nil }
                let totalLines = fileCoverages.reduce(0) { $0 + $1.totalLines }
                let totalCoveredLines = fileCoverages.reduce(0) { $0 + $1.coveredLines }
                return totalLines != 0 ? Double(totalCoveredLines) / Double(totalLines) : 0.0
            }() : nil

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
