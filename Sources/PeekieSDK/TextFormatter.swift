import Foundation

extension TextFormatter {
    /// Output format options
    public enum Format: String, Decodable {
        case list  // Outputs detailed list of test results
        case count  // // Outputs a summary count of test results
    }
}

public class TextFormatter {
    public init() {}

    /// Formats a given report based on specified criteria.
    ///
    /// This method takes a `Report` instance and formats it according to the provided parameters.
    /// It allows filtering based on the status of tests within the report and supports different formatting styles.
    /// The method can also localize the output based on the provided locale.
    ///
    /// - Parameters:
    ///   - report: The report model instance to be formatted.
    ///   - include: An array of `Report.Module.File.RepeatableTest.Test.Status` values that specifies which test statuses to include in the formatted report.
    ///   - format: The formatting style to be applied to the report.
    ///   - locale: An optional `Locale` to localize the formatted report. If nil, the system locale is used.
    ///
    /// - Returns: A formatted string representation of the report based on the specified criteria.
    ///
    /// - Throws: This method may throw an error if the formatting fails for any reason, such as an issue with the report model.
    public func format(
        _ report: Report,
        include: [Report.Module.File.RepeatableTest.Test.Status] = Report.Module
            .File.RepeatableTest.Test.Status.allCases,
        format: Format = .list,
        locale: Locale? = nil
    ) -> String {
        let files = report.modules
            .flatMap { Array($0.files) }
            .sorted { $0.name < $1.name }

        switch format {
        case .list:
            let filesReports = files.compactMap { file in
                file.report(testResults: include)
            }
            return filesReports.joined(separator: "\n\n")
        case .count:
            let numberFormatter = NumberFormatter.testsCountFormatter
            numberFormatter.locale = locale
            let totalTestsMeasurementFormatter = MeasurementFormatter.totalTestsDurationFormatter
            totalTestsMeasurementFormatter.locale = locale
            let tests = files.flatMap { $0.repeatableTests.filtered(testResults: include) }
            let count = tests.count
            let duration = tests.totalDuration
            // don't add 0ms duration if requested only skipped tests
            let addDuration = include != [.skipped]
            return [
                numberFormatter.string(from: NSNumber(value: count)) ?? String(count),
                addDuration
                    ? totalTestsMeasurementFormatter.string(from: duration).wrappedInBrackets : nil,
            ]
            .compactMap { $0 }
            .joined(separator: " ")
        }
    }
}

extension Report.Module.File {
    func report(
        testResults: [Report.Module.File.RepeatableTest.Test.Status]
    ) -> String? {
        let tests = repeatableTests.filtered(testResults: testResults).sorted { $0.name < $1.name }

        guard !tests.isEmpty else {
            return nil
        }

        var rows: [String] = []
        for repeatableTest in tests.sorted(by: { $0.name < $1.name }) {
            // If there are multiple tests with different messages (likely from arguments),
            // output each separately with its own status
            // Check if tests have different messages, which indicates they're from arguments
            let hasDifferentMessages =
                repeatableTest.tests.count > 1
                && Set(repeatableTest.tests.compactMap { $0.message }).count
                    == repeatableTest.tests.count

            if hasDifferentMessages {
                // Output each test separately (arguments case)
                for test in repeatableTest.tests {
                    rows.append(
                        test.report(repeatableTestName: repeatableTest.name))
                }
            } else {
                // Single test or multiple tests with same message (repetitions/mixed), use original format
                rows.append(repeatableTest.report())
            }
        }

        rows.insert(name, at: 0)

        return rows.joined(separator: "\n")
    }
}

extension Report.Module.File.RepeatableTest {
    fileprivate func report() -> String {
        [
            combinedStatus.icon,
            name,
            message?.wrappedInBrackets,
        ]
        .compactMap { $0 }
        .joined(separator: " ")
    }
}

extension Report.Module.File.RepeatableTest.Test {
    fileprivate func report(repeatableTestName: String) -> String {
        [
            status.icon,
            repeatableTestName,
            message?.wrappedInBrackets,
        ]
        .compactMap { $0 }
        .joined(separator: " ")
    }
}

extension String {
    var wrappedInBrackets: Self {
        "(" + self + ")"
    }
}

extension MeasurementFormatter {
    static var totalTestsDurationFormatter: MeasurementFormatter {
        let formatter = MeasurementFormatter()
        formatter.unitOptions = [.naturalScale]
        formatter.numberFormatter.maximumFractionDigits = 0
        return formatter
    }
}

extension NumberFormatter {
    static var testsCountFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 0
        return formatter
    }
}
