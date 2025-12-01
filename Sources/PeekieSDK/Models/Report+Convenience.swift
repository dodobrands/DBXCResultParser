import Foundation
import Logging

extension Report {
    private static let logger = Logger(label: "com.peekie.report")
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
        Self.logger.debug(
            "Initializing Report from xcresult",
            metadata: [
                "xcresultPath": "\(xcresultPath.path)",
                "includeCoverage": "\(includeCoverage)",
                "includeWarnings": "\(includeWarnings)",
            ]
        )

        let testResultsDTO = try await TestResultsDTO(from: xcresultPath)
        Self.logger.debug("TestResultsDTO loaded")

        let buildResultsDTO: BuildResultsDTO? =
            includeWarnings ? try await BuildResultsDTO(from: xcresultPath) : nil
        if includeWarnings {
            Self.logger.debug("BuildResultsDTO loaded")
        }

        let coverageReportDTO: CoverageReportDTO? =
            includeCoverage ? try await CoverageReportDTO(from: xcresultPath) : nil
        if includeCoverage {
            Self.logger.debug("CoverageReportDTO loaded")
        }

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
        let warningsByFileName: [String: [Report.Module.Suite.Issue]]
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
                Self.logger.debug(
                    "Processing module",
                    metadata: [
                        "moduleName": "\(moduleName)"
                    ]
                )

                // Find coverage suites for this module
                // Coverage is organized by target (source module), not test module
                // We need to find all coverage suites that belong to this test module's source
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
                                // Use suite name (without path) as key
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
                        suites: [],
                        coverage: matchedTargetCoverage
                    )

                // Process test suites
                guard let testSuites = testNode.children else { continue }
                for testSuite in testSuites {
                    guard testSuite.nodeType == .testSuite else { continue }

                    // Extract suite name from test suite name (e.g., "ReportTests")
                    let suiteName = testSuite.name

                    // Store nodeIdentifierURL for fileName computation
                    let nodeIdentifierURL = testSuite.nodeIdentifierURL

                    // Try to find coverage for this suite by name or path
                    let suiteCoverage: Report.Module.Suite.Coverage?
                    if includeCoverage {
                        // First try by exact suite name
                        if let coverageDTO = fileCoverageMap[suiteName] {
                            suiteCoverage = Report.Module.Suite.Coverage(from: coverageDTO)
                        } else {
                            // Try with .swift extension
                            let suiteNameWithExtension = suiteName + ".swift"
                            if let coverageDTO = fileCoverageMap[suiteNameWithExtension] {
                                suiteCoverage = Report.Module.Suite.Coverage(from: coverageDTO)
                            } else {
                                // Try to match by extracting base name from test suite
                                // Test suite names might be like "ReportTests" but suite might be "Report.swift"
                                let baseName = suiteName.replacingOccurrences(of: "Tests", with: "")
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
                                    // Try to find in module-specific coverage suites
                                    for (key, coverageDTO) in moduleCoverageFiles {
                                        // Match by exact key or by comparing names (with/without .swift)
                                        let coverageNameWithoutExt =
                                            coverageDTO.name.hasSuffix(".swift")
                                            ? String(coverageDTO.name.dropLast(6))
                                            : coverageDTO.name
                                        if key == suiteName
                                            || key == suiteName + ".swift"
                                            || key.contains(suiteName)
                                            || suiteName == coverageNameWithoutExt
                                            || suiteName == coverageDTO.name
                                        {
                                            found = coverageDTO
                                            break
                                        }
                                    }
                                }
                                if found == nil {
                                    // Try to find by matching suite name in path
                                    for (path, coverageDTO) in fileCoverageMap {
                                        // Match by exact path or by comparing names (with/without .swift)
                                        let coverageNameWithoutExt =
                                            coverageDTO.name.hasSuffix(".swift")
                                            ? String(coverageDTO.name.dropLast(6))
                                            : coverageDTO.name
                                        if path == suiteName
                                            || path == suiteName + ".swift"
                                            || path.contains(suiteName)
                                            || suiteName == coverageNameWithoutExt
                                            || suiteName == coverageDTO.name
                                        {
                                            found = coverageDTO
                                            break
                                        }
                                    }
                                }
                                suiteCoverage = found.map { Report.Module.Suite.Coverage(from: $0) }
                            }
                        }
                    } else {
                        suiteCoverage = nil
                    }

                    let suiteWarnings: [Report.Module.Suite.Issue] =
                        includeWarnings
                        ? Self.warningsFor(fileName: suiteName, in: warningsByFileName)
                        : []
                    // Get existing suite or create new one
                    var suite: Report.Module.Suite
                    if let existingSuite = module.suites[suiteName] {
                        // Update existing suite with nodeIdentifierURL if it wasn't set before
                        if existingSuite.nodeIdentifierURL == nil && nodeIdentifierURL != nil {
                            suite = .init(
                                name: suiteName,
                                nodeIdentifierURL: nodeIdentifierURL,
                                repeatableTests: existingSuite.repeatableTests,
                                warnings: existingSuite.warnings,
                                coverage: existingSuite.coverage ?? suiteCoverage
                            )
                        } else {
                            suite = existingSuite
                        }
                    } else {
                        suite = .init(
                            name: suiteName,
                            nodeIdentifierURL: nodeIdentifierURL,
                            repeatableTests: [],
                            warnings: suiteWarnings,
                            coverage: suiteCoverage
                        )
                    }

                    if includeWarnings && !suiteWarnings.isEmpty {
                        suite.warnings = Self.mergeWarnings(suite.warnings, suiteWarnings)
                    }

                    // Process test cases
                    guard let testCases = testSuite.children else { continue }
                    for testCase in testCases {
                        guard testCase.nodeType == .testCase else { continue }

                        let testName = testCase.name
                        var repeatableTest =
                            suite.repeatableTests[testName]
                            ?? Report.Module.Suite.RepeatableTest(
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
                            path: [Report.Module.Suite.RepeatableTest.PathNode],
                            testCase: TestResultsDTO.TestNode
                        ) throws {
                            // Check if this node should be added to path
                            let pathNode: Report.Module.Suite.RepeatableTest.PathNode?
                            switch node.nodeType {
                            case .device, .arguments, .repetition:
                                // Convert result from DTO to Test.Status
                                let result: Report.Module.Suite.RepeatableTest.Test.Status? = {
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
                                        unit: Report.Module.Suite.RepeatableTest.Test
                                            .defaultDurationUnit
                                    )
                                }()

                                // Extract message from DTO
                                let message = node.failureMessage ?? node.skipMessage

                                pathNode = Report.Module.Suite.RepeatableTest.PathNode(
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
                                let test = try Report.Module.Suite.RepeatableTest.Test(
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
                                    let test = Report.Module.Suite.RepeatableTest.Test(
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
                                    let test = Report.Module.Suite.RepeatableTest.Test(
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
                        if repeatableTest.tests.isEmpty {
                            let test = Report.Module.Suite.RepeatableTest.Test(from: testCase)
                            repeatableTest.tests.append(test)
                        }

                        suite.repeatableTests.update(with: repeatableTest)
                    }

                    module.suites.update(with: suite)
                }

                // Update module in set, preserving coverage
                if let existingModule = modules[moduleName] {
                    modules.remove(existingModule)
                }
                modules.insert(module)
            }
        }

        // Add all suites with coverage to modules, even if they don't have test suites
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

                // Start with existing module suites or empty set
                var moduleSuites = existingModule?.suites ?? Set<Report.Module.Suite>()

                // Determine module coverage: use target coverage if module doesn't have one, or keep existing
                let moduleCoverage = existingModule?.coverage ?? targetCoverage

                // Add all coverage suites to this module
                for fileCoverageDTO in target.files {
                    let coverage = Report.Module.Suite.Coverage(from: fileCoverageDTO)
                    // Use the name as it appears in xcresult
                    // If name contains path separators, extract just the suite name
                    var suiteName = fileCoverageDTO.name
                    if let lastSlash = suiteName.lastIndex(of: "/") {
                        suiteName = String(suiteName[suiteName.index(after: lastSlash)...])
                    }

                    // Check if suite already exists in module (from test suites)
                    if let existingSuite = moduleSuites[suiteName] {
                        // Suite exists - update coverage if it doesn't have one
                        if existingSuite.coverage == nil {
                            let updatedWarnings: [Report.Module.Suite.Issue] =
                                includeWarnings
                                ? Self.mergeWarnings(
                                    existingSuite.warnings,
                                    Self.warningsFor(fileName: suiteName, in: warningsByFileName)
                                )
                                : existingSuite.warnings
                            let updatedSuite = Report.Module.Suite(
                                name: suiteName,
                                nodeIdentifierURL: existingSuite.nodeIdentifierURL,
                                repeatableTests: existingSuite.repeatableTests,
                                warnings: updatedWarnings,
                                coverage: coverage
                            )
                            moduleSuites.remove(existingSuite)
                            moduleSuites.insert(updatedSuite)
                        }
                        // If suite already has coverage, keep existing one (from test suite matching)
                    } else {
                        // Create new suite entry with coverage but no tests
                        let newSuiteWarnings: [Report.Module.Suite.Issue] =
                            includeWarnings
                            ? Self.warningsFor(fileName: suiteName, in: warningsByFileName)
                            : []
                        let newSuite = Report.Module.Suite(
                            name: suiteName,
                            nodeIdentifierURL: nil,
                            repeatableTests: [],
                            warnings: newSuiteWarnings,
                            coverage: coverage
                        )
                        moduleSuites.insert(newSuite)
                    }
                }

                // Remove old module if it existed and add updated one
                if let oldModule = existingModule {
                    modules.remove(oldModule)
                }

                // Create or update module with all suites and coverage
                let updatedModule = Report.Module(
                    name: moduleName, suites: moduleSuites, coverage: moduleCoverage)
                modules.insert(updatedModule)
            }
        }

        // Use total coverage from xcresult file if available, otherwise calculate from suites
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

                let suiteCoverages = modules.flatMap { $0.suites }.compactMap { $0.coverage }
                guard !suiteCoverages.isEmpty else { return nil }
                let totalLines = suiteCoverages.reduce(0) { $0 + $1.totalLines }
                let totalCoveredLines = suiteCoverages.reduce(0) { $0 + $1.coveredLines }
                return totalLines != 0 ? Double(totalCoveredLines) / Double(totalLines) : 0.0
            }() : nil

        self.modules = modules
        self.coverage = totalCoverage

        Self.logger.debug(
            "Report initialization completed",
            metadata: [
                "modulesCount": "\(modules.count)",
                "totalCoverage": totalCoverage.map { "\($0)" } ?? "nil",
            ]
        )
    }
}
