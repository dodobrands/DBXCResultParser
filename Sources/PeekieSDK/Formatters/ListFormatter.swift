import Foundation

public class ListFormatter {
    public init() {}

    /// Formats a given report based on specified criteria.
    ///
    /// This method takes a `Report` instance and formats it according to the provided parameters.
    /// It allows filtering based on the status of tests within the report.
    ///
    /// - Parameters:
    ///   - report: The report model instance to be formatted.
    ///   - include: An array of `Report.Module.File.RepeatableTest.Test.Status` values that specifies which test statuses to include in the formatted report.
    ///   - includeDeviceDetails: If true, device information is included in test names. Defaults to false.
    ///
    /// - Returns: A formatted string representation of the report based on the specified criteria.
    ///
    /// - Throws: This method may throw an error if the formatting fails for any reason, such as an issue with the report model.
    public func format(
        _ report: Report,
        include: [Report.Module.File.RepeatableTest.Test.Status] = Report.Module
            .File.RepeatableTest.Test.Status.allCases,
        includeDeviceDetails: Bool = false
    ) -> String {
        let files = report.modules
            .flatMap { Array($0.files) }
            .sorted { $0.name < $1.name }

        let filesReports = files.compactMap { file in
            file.report(testResults: include, includeDeviceDetails: includeDeviceDetails)
        }
        return filesReports.joined(separator: "\n\n")
    }
}

extension Report.Module.File {
    func report(
        testResults: [Report.Module.File.RepeatableTest.Test.Status],
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

extension Report.Module.File.RepeatableTest.Test {
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
