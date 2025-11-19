//
//  DBXCReportModelValuesTests.swift
//
//
//  Created on 19.11.2025.
//

import Foundation
import Testing

@testable import DBXCResultParser

@Suite
struct DBXCReportModelValuesTests {
    @Test(arguments: Constants.testsReportFileNames)
    func test_coverageValues(fileName: String) async throws {
        let reportPath = try Constants.url(for: fileName)
        let report = try await DBXCReportModel(xcresultPath: reportPath)
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
        // Modules in report are test modules (e.g., "DBXCResultParserTests")
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
        let reportPath = try Constants.url(for: fileName)
        let report = try await DBXCReportModel(xcresultPath: reportPath)
        let expected = try Constants.expectedWarningsValues(for: fileName)

        // Check warnings count exactly as in xcresult file
        #expect(report.warnings.count == expected.warningCount)
    }
}
