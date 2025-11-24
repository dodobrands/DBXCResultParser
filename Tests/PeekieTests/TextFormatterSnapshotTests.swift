import Foundation
import PeekieTestHelpers
import SnapshotTesting
import Testing

@testable import PeekieSDK

@Suite
struct TextFormatterSnapshotTests {
    let locale = Locale(identifier: "en-US")
    let formatter = TextFormatter()

    @Test(arguments: Constants.testsReportFileNames)
    func listFormat_allStatuses(_ fileName: String) async throws {
        let originalPath = try Constants.url(for: fileName)
        let reportPath = try Constants.copyXcresultToTemporaryDirectory(originalPath)
        defer {
            try? FileManager.default.removeItem(at: reportPath)
        }
        let report = try await Report(xcresultPath: reportPath)
        let formatted = formatter.format(report, locale: locale)

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
            locale: locale
        )

        assertSnapshot(
            of: formatted,
            as: .lines,
            named: "\(snapshotName(from: fileName))_list_skipped"
        )
    }

}
