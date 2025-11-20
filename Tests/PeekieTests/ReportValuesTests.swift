import Foundation
import Testing

@testable import peekiesdk

@Suite
struct ReportValuesTests {
    @Test(arguments: Constants.testsReportFileNames)
    func test_coverageValues(fileName: String) async throws {
        let originalPath = try Constants.url(for: fileName)
        let reportPath = try Constants.copyXcresultToTemporaryDirectory(originalPath)
        defer {
            try? FileManager.default.removeItem(at: reportPath)
        }
        let report = try await Report(xcresultPath: reportPath)
        let expected = try Constants.expectedReportValues(for: fileName)

        // Calculate total covered lines from all modules
        let totalCoveredLines = report.modules
            .compactMap { $0.coverage }
            .reduce(0) { $0 + $1.coveredLines }

        // Check covered lines exactly as in xcresult file
        #expect(totalCoveredLines == expected.coveredLines)

        // Check coverage percentage exactly as in xcresult file
        let coverage = try #require(report.coverage, "Coverage data not available")
        #expect(coverage == expected.coveragePercentage)

        // Check coverage for each module
        // Modules in report are test modules (e.g., "PeekieTests")
        // Coverage is attached to test modules based on source module names
        for (moduleName, expectedModuleCoverage) in expected.moduleCoverages {
            let module = try #require(
                report.modules.first(where: { $0.name == moduleName }),
                "Module \(moduleName) not found"
            )
            let moduleCoverage = try #require(
                module.coverage,
                "Coverage data not available for module \(moduleName)"
            )
            #expect(moduleCoverage.coverage == expectedModuleCoverage)
        }
    }

    @Test(arguments: Constants.testsReportFileNames)
    func test_warningsValues(fileName: String) async throws {
        let originalPath = try Constants.url(for: fileName)
        let reportPath = try Constants.copyXcresultToTemporaryDirectory(originalPath)
        defer {
            try? FileManager.default.removeItem(at: reportPath)
        }
        let report = try await Report(xcresultPath: reportPath)
        let expected = try Constants.expectedWarningsValues(for: fileName)

        // Check warnings count exactly as in xcresult file
        #expect(report.warnings.count == expected.warningCount)

        // Check warnings details if expected warnings are provided
        if !expected.warnings.isEmpty {
            #expect(report.warnings.count == expected.warnings.count)

            for (index, expectedWarning) in expected.warnings.enumerated() {
                let actualWarning = report.warnings[index]
                #expect(actualWarning.message == expectedWarning.message)

                // Check sourceURL - it may contain timestamp, so compare only the file path part
                // Extract file path without query parameters (timestamp)
                let expectedPath =
                    URL(string: expectedWarning.sourceURL)?.path ?? expectedWarning.sourceURL
                let actualPath =
                    URL(string: actualWarning.sourceURL)?.path ?? actualWarning.sourceURL
                #expect(actualPath == expectedPath)

                #expect(actualWarning.className == expectedWarning.className)
            }
        }
    }
}
