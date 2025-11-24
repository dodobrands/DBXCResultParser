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
    ///
    /// - Returns: A formatted string representation of the report based on the specified criteria.
    ///
    /// - Throws: This method may throw an error if the formatting fails for any reason, such as an issue with the report model.
    public func format(
        _ report: Report,
        include: [Report.Module.File.RepeatableTest.Test.Status] = Report.Module
            .File.RepeatableTest.Test.Status.allCases
    ) -> String {
        let files = report.modules
            .flatMap { Array($0.files) }
            .sorted { $0.name < $1.name }

        let filesReports = files.compactMap { file in
            file.report(testResults: include)
        }
        return filesReports.joined(separator: "\n\n")
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
