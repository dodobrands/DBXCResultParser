import Foundation
import SnapshotTesting
import Testing

@testable import peekiesdk

@Suite
struct DBXCTextFormatterSnapshotTests {
    let locale = Locale(identifier: "en-US")
    let formatter = DBXCTextFormatter()

    @Test(arguments: Constants.testsReportFileNames)
    func test_listFormat_allStatuses(fileName: String) async throws {
        let originalPath = try Constants.url(for: fileName)
        let reportPath = try Constants.copyXcresultToTemporaryDirectory(originalPath)
        defer {
            try? FileManager.default.removeItem(at: reportPath)
        }
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
        let originalPath = try Constants.url(for: fileName)
        let reportPath = try Constants.copyXcresultToTemporaryDirectory(originalPath)
        defer {
            try? FileManager.default.removeItem(at: reportPath)
        }
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
        let originalPath = try Constants.url(for: fileName)
        let reportPath = try Constants.copyXcresultToTemporaryDirectory(originalPath)
        defer {
            try? FileManager.default.removeItem(at: reportPath)
        }
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
        let originalPath = try Constants.url(for: fileName)
        let reportPath = try Constants.copyXcresultToTemporaryDirectory(originalPath)
        defer {
            try? FileManager.default.removeItem(at: reportPath)
        }
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
        let originalPath = try Constants.url(for: fileName)
        let reportPath = try Constants.copyXcresultToTemporaryDirectory(originalPath)
        defer {
            try? FileManager.default.removeItem(at: reportPath)
        }
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
        let originalPath = try Constants.url(for: fileName)
        let reportPath = try Constants.copyXcresultToTemporaryDirectory(originalPath)
        defer {
            try? FileManager.default.removeItem(at: reportPath)
        }
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

}
