import Foundation
import SnapshotTesting
import Testing

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
        let testsPath = try createTestDirectory(for: report, functionName: #function)
        defer {
            try? FileManager.default.removeItem(at: testsPath)
        }

        let formatted = try formatter.format(report: report, testsPath: testsPath)

        assertSnapshot(
            of: formatted,
            as: .lines,
            named: "\(fileName)_sonar"
        )
    }

    // MARK: - Helpers

    private func createTestDirectory(for report: Report, functionName: String) throws -> URL {
        // Use function name in temporary directory for stable snapshot paths per test
        let tempDir = FileManager.default.temporaryDirectory
        let testDir = tempDir.appendingPathComponent("PeekieSonarTests-\(functionName)")

        // Remove existing directory if present to ensure clean state
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
