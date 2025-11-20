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

        // Copy all actual test files from Tests/PeekieTests to the temporary directory
        let testsSourceDir = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()  // Remove SonarFormatterSnapshotTests.swift
        let fileManager = FileManager.default

        // Find all .swift files in the tests directory
        let enumerator = fileManager.enumerator(
            at: testsSourceDir,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        )

        while let element = enumerator?.nextObject() as? URL {
            guard try element.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile == true,
                element.pathExtension == "swift"
            else {
                continue
            }

            // Calculate relative path from tests source directory
            guard let relativePath = element.relativePath(from: testsSourceDir) else {
                continue
            }
            let destinationPath = testDir.appendingPathComponent(relativePath)

            // Create destination directory if needed
            try fileManager.createDirectory(
                at: destinationPath.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )

            // Remove existing file if present (can happen with parallel test execution)
            if fileManager.fileExists(atPath: destinationPath.path) {
                try fileManager.removeItem(at: destinationPath)
            }

            // Copy the file
            try fileManager.copyItem(at: element, to: destinationPath)
        }

        // Return standardized URL to avoid /private/var vs /var issues
        return URL(fileURLWithPath: testDir.path).standardized
    }
}
