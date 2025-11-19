import DBXCResultParser_TextFormatter
import Foundation
import SnapshotTesting
import Testing

@testable import DBXCResultParser

@Suite
struct DBXCTextFormatterSnapshotTests {
    let locale = Locale(identifier: "en-US")
    let formatter = DBXCTextFormatter()

    @Test(arguments: Constants.testsReportFileNames)
    func test_listFormat_allStatuses(fileName: String) async throws {
        let reportPath = try Constants.url(for: fileName)
        let report = try await DBXCReportModel(xcresultPath: reportPath)
        let formatted = formatter.format(report, format: .list, locale: locale)

        assertSnapshot(
            of: formatted,
            as: .lines,
            named: "\(fileName)_list_all"
        )
    }

    @Test(arguments: Constants.testsReportFileNames)
    func test_listFormat_successOnly(fileName: String) async throws {
        let reportPath = try Constants.url(for: fileName)
        let report = try await DBXCReportModel(xcresultPath: reportPath)
        let formatted = formatter.format(
            report,
            include: [.success],
            format: .list,
            locale: locale
        )

        assertSnapshot(
            of: formatted,
            as: .lines,
            named: "\(fileName)_list_success"
        )
    }

    @Test(arguments: Constants.testsReportFileNames)
    func test_listFormat_failureOnly(fileName: String) async throws {
        let reportPath = try Constants.url(for: fileName)
        let report = try await DBXCReportModel(xcresultPath: reportPath)
        let formatted = formatter.format(
            report,
            include: [.failure],
            format: .list,
            locale: locale
        )

        assertSnapshot(
            of: formatted,
            as: .lines,
            named: "\(fileName)_list_failure"
        )
    }

    @Test(arguments: Constants.testsReportFileNames)
    func test_listFormat_skippedOnly(fileName: String) async throws {
        let reportPath = try Constants.url(for: fileName)
        let report = try await DBXCReportModel(xcresultPath: reportPath)
        let formatted = formatter.format(
            report,
            include: [.skipped],
            format: .list,
            locale: locale
        )

        assertSnapshot(
            of: formatted,
            as: .lines,
            named: "\(fileName)_list_skipped"
        )
    }

    @Test(arguments: Constants.testsReportFileNames)
    func test_countFormat_allStatuses(fileName: String) async throws {
        let reportPath = try Constants.url(for: fileName)
        let report = try await DBXCReportModel(xcresultPath: reportPath)
        let formatted = formatter.format(report, format: .count, locale: locale)

        assertSnapshot(
            of: formatted,
            as: .lines,
            named: "\(fileName)_count_all"
        )
    }

    @Test(arguments: Constants.testsReportFileNames)
    func test_countFormat_failureOnly(fileName: String) async throws {
        let reportPath = try Constants.url(for: fileName)
        let report = try await DBXCReportModel(xcresultPath: reportPath)
        let formatted = formatter.format(
            report,
            include: [.failure],
            format: .count,
            locale: locale
        )

        assertSnapshot(
            of: formatted,
            as: .lines,
            named: "\(fileName)_count_failure"
        )
    }

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
        guard let coverage = report.coverage else {
            Issue.record("Coverage data not available")
            return
        }
        let coveragePercentage = coverage * 100.0
        #expect(coveragePercentage == expected.coveragePercentage)
    }
}
