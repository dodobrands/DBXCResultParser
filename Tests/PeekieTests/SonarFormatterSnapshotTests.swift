import Foundation
import SnapshotTesting
import Testing

@testable import Peekie
@testable import PeekieSDK

@Suite
struct SonarFormatterSnapshotTests {
    let formatter = SonarFormatter()

    @Test(arguments: Constants.testsReportFileNames)
    func test_sonarFormat_allStatuses(fileName: String) async throws {
        let originalPath = try Constants.url(for: fileName)
        let reportPath = try Constants.copyXcresultToTemporaryDirectory(originalPath)
        defer {
            try? FileManager.default.removeItem(at: reportPath)
        }
        let report = try await Report(xcresultPath: reportPath)

        // Create temporary test directory with mock test files
        let testsPath = try createTestDirectory(for: report)
        defer {
            try? FileManager.default.removeItem(at: testsPath)
        }

        let formatted = try formatter.format(report: report, testsPath: testsPath)

        assertSnapshot(
            of: formatted,
            as: .lines,
            named: "\(fileName)_sonar_all"
        )
    }

    // MARK: - Helpers

    private func createTestDirectory(for report: Report) throws -> URL {
        // Use a fixed location in temporary directory to avoid path resolution issues
        let tempDir = FileManager.default.temporaryDirectory
        let testDir = tempDir.appendingPathComponent("PeekieSonarTests")

        // Remove existing directory if present
        if FileManager.default.fileExists(atPath: testDir.path) {
            try? FileManager.default.removeItem(at: testDir)
        }
        try FileManager.default.createDirectory(at: testDir, withIntermediateDirectories: true)

        // Extract all file names from report and create mock Swift files
        let fileNames = report.modules
            .flatMap { $0.files }
            .map { $0.name }

        for fileName in fileNames {
            // Create a simple Swift file with a class matching the file name
            // Remove file extension if present
            let className = fileName.replacingOccurrences(of: ".swift", with: "")
            let swiftContent = "class \(className) {}"
            let filePath = testDir.appendingPathComponent("\(className).swift")
            try swiftContent.write(to: filePath, atomically: true, encoding: .utf8)
        }

        // Return standardized URL to avoid /private/var vs /var issues
        return URL(fileURLWithPath: testDir.path).standardized
    }
}
