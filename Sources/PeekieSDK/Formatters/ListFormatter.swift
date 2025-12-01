import Foundation
import Logging

public class ListFormatter {
    private let logger = Logger(label: "com.peekie.formatter")

    public init() {}

    /// Formats a given report based on specified criteria.
    ///
    /// This method takes a `Report` instance and formats it according to the provided parameters.
    /// It allows filtering based on the status of tests within the report.
    ///
    /// - Parameters:
    ///   - report: The report model instance to be formatted.
    ///   - include: An array of `Report.Module.Suite.RepeatableTest.Test.Status` values that specifies which test statuses to include in the formatted report.
    ///   - includeDeviceDetails: If true, device information is included in test names. Defaults to false.
    ///
    /// - Returns: A formatted string representation of the report based on the specified criteria.
    ///
    /// - Throws: This method may throw an error if the formatting fails for any reason, such as an issue with the report model.
    public func format(
        _ report: Report,
        include: [Report.Module.Suite.RepeatableTest.Test.Status] = Report.Module
            .Suite.RepeatableTest.Test.Status.allCases,
        includeDeviceDetails: Bool = false
    ) -> String {
        logger.debug(
            "Formatting report",
            metadata: [
                "modulesCount": "\(report.modules.count)",
                "includeStatuses": "\(include.map { $0.rawValue }.joined(separator: ","))",
                "includeDeviceDetails": "\(includeDeviceDetails)",
            ]
        )

        let files = report.modules
            .flatMap { Array($0.suites) }
            .sorted { $0.name < $1.name }

        let filesReports = files.compactMap { file in
            file.report(testResults: include, includeDeviceDetails: includeDeviceDetails)
        }

        logger.debug(
            "Formatting completed",
            metadata: [
                "filesCount": "\(files.count)",
                "filesWithResults": "\(filesReports.count)",
            ]
        )

        return filesReports.joined(separator: "\n\n")
    }
}

extension Report.Module.Suite {
    func report(
        testResults: [Report.Module.Suite.RepeatableTest.Test.Status],
        includeDeviceDetails: Bool
    ) -> String? {
        let tests = repeatableTests.filtered(testResults: testResults).sorted { $0.name < $1.name }

        guard !tests.isEmpty else {
            return nil
        }

        var rows: [String] = []
        for repeatableTest in tests.sorted(by: { $0.name < $1.name }) {
            // Use merged tests which already handle repetitions and optionally devices
            let mergedTests = repeatableTest.mergedTests(filterDevice: !includeDeviceDetails)
                .filter { testResults.contains($0.status) }

            // Output each merged test separately
            for test in mergedTests {
                rows.append(test.report())
            }
        }

        rows.insert(name, at: 0)

        return rows.joined(separator: "\n")
    }
}

extension Report.Module.Suite.RepeatableTest.Test {
    fileprivate func report() -> String {
        [
            status.icon,
            name,
            message.map { "(\($0))" },
        ]
        .compactMap { $0 }
        .joined(separator: " ")
    }
}
