import Foundation
import SnapshotTesting
import Testing

@testable import PeekieSDK

@Suite
struct ReportSnapshotTests {
    private func snapshotName(from fileName: String) -> String {
        fileName.replacingOccurrences(of: ".xcresult", with: "")
    }

    @Test(arguments: Constants.testsReportFileNames)
    func coverageValues(_ fileName: String) async throws {
        let originalPath = try Constants.url(for: fileName)
        let reportPath = try Constants.copyXcresultToTemporaryDirectory(originalPath)
        defer {
            try? FileManager.default.removeItem(at: reportPath)
        }
        let report = try await Report(xcresultPath: reportPath)

        assertSnapshot(
            of: report,
            as: .dump,
            named: snapshotName(from: fileName)
        )
    }
}
