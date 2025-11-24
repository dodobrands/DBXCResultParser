import Foundation
import SnapshotTesting
import Testing

@testable import PeekieSDK

@Suite
struct TextFormatterSnapshotTests {
    let locale = Locale(identifier: "en-US")
    let formatter = TextFormatter()

    private func snapshotName(from fileName: String) -> String {
        fileName.replacingOccurrences(of: ".xcresult", with: "")
    }

    @Test(arguments: Constants.testsReportFileNames)
    func listFormat_allStatuses(_ fileName: String) async throws {
        let originalPath = try Constants.url(for: fileName)
        let reportPath = try Constants.copyXcresultToTemporaryDirectory(originalPath)
        defer {
            try? FileManager.default.removeItem(at: reportPath)
        }
        let report = try await Report(xcresultPath: reportPath)
        let formatted = formatter.format(report, format: .list, locale: locale)

        assertSnapshot(
            of: formatted,
            as: .lines,
            named: "\(snapshotName(from: fileName))_list_all"
        )
    }

    @Test(arguments: Constants.testsReportFileNames)
    func listFormat_successOnly(_ fileName: String) async throws {
        let originalPath = try Constants.url(for: fileName)
        let reportPath = try Constants.copyXcresultToTemporaryDirectory(originalPath)
        defer {
            try? FileManager.default.removeItem(at: reportPath)
        }
        let report = try await Report(xcresultPath: reportPath)
        let formatted = formatter.format(
            report,
            include: [.success],
            format: .list,
            locale: locale
        )

        assertSnapshot(
            of: formatted,
            as: .lines,
            named: "\(snapshotName(from: fileName))_list_success"
        )
    }

    @Test(arguments: Constants.testsReportFileNames)
    func listFormat_failureOnly(_ fileName: String) async throws {
        let originalPath = try Constants.url(for: fileName)
        let reportPath = try Constants.copyXcresultToTemporaryDirectory(originalPath)
        defer {
            try? FileManager.default.removeItem(at: reportPath)
        }
        let report = try await Report(xcresultPath: reportPath)
        let formatted = formatter.format(
            report,
            include: [.failure],
            format: .list,
            locale: locale
        )

        assertSnapshot(
            of: formatted,
            as: .lines,
            named: "\(snapshotName(from: fileName))_list_failure"
        )
    }

    @Test(arguments: Constants.testsReportFileNames)
    func listFormat_skippedOnly(_ fileName: String) async throws {
        let originalPath = try Constants.url(for: fileName)
        let reportPath = try Constants.copyXcresultToTemporaryDirectory(originalPath)
        defer {
            try? FileManager.default.removeItem(at: reportPath)
        }
        let report = try await Report(xcresultPath: reportPath)
        let formatted = formatter.format(
            report,
            include: [.skipped],
            format: .list,
            locale: locale
        )

        assertSnapshot(
            of: formatted,
            as: .lines,
            named: "\(snapshotName(from: fileName))_list_skipped"
        )
    }

    @Test(arguments: Constants.testsReportFileNames)
    func countFormat_allStatuses(_ fileName: String) async throws {
        let originalPath = try Constants.url(for: fileName)
        let reportPath = try Constants.copyXcresultToTemporaryDirectory(originalPath)
        defer {
            try? FileManager.default.removeItem(at: reportPath)
        }
        let report = try await Report(xcresultPath: reportPath)
        let formatted = formatter.format(report, format: .count, locale: locale)

        assertSnapshot(
            of: formatted,
            as: .lines,
            named: "\(snapshotName(from: fileName))_count_all"
        )
    }

    @Test(arguments: Constants.testsReportFileNames)
    func countFormat_failureOnly(_ fileName: String) async throws {
        let originalPath = try Constants.url(for: fileName)
        let reportPath = try Constants.copyXcresultToTemporaryDirectory(originalPath)
        defer {
            try? FileManager.default.removeItem(at: reportPath)
        }
        let report = try await Report(xcresultPath: reportPath)
        let formatted = formatter.format(
            report,
            include: [.failure],
            format: .count,
            locale: locale
        )

        assertSnapshot(
            of: formatted,
            as: .lines,
            named: "\(snapshotName(from: fileName))_count_failure"
        )
    }

}
