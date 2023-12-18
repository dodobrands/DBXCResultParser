//
//  DBXCTextFormatter.swift
//  
//
//  Created by Алексей Берёзка on 31.12.2021.
//

import Foundation

extension DBXCTextFormatter {
    /// Output format options
    public enum Format {
        case list // Outputs detailed list of test results
        case count // // Outputs a summary count of test results
    }
}

public class DBXCTextFormatter {
    /// The format style to use for output
    public let format: Format
    
    /// /// The locale to use for formatting numbers and measurements
    public let locale: Locale?
    
    /// Initializes a new text formatter with the specified format and locale.
    ///
    /// - Parameters:
    ///   - format: The output format to use.
    ///   - locale: The locale for number and measurement formatting. Defaults to `nil`.
    public init(
        format: Format,
        locale: Locale? = nil
    ) {
        self.format = format
        self.locale = locale
    }
    
    /// Formats the test report data into a string based on the specified format.
    ///
    /// - Parameters:
    ///   - report: The `DBXCReportModel` containing the test report data.
    ///   - testResults: The test result statuses to include in the output. Defaults to all test statuses.
    /// - Returns: A formatted string representation of the report data.
    public func format(
        _ report: DBXCReportModel,
        testResults: [DBXCReportModel.Module.File.RepeatableTest.Test.Status] = .allCases
    ) -> String {
        let files = report.modules
            .flatMap { Array($0.files) }
            .sorted { $0.name < $1.name }
        
        switch format {
        case .list:
            let singleTestsMeasurementFormatter = MeasurementFormatter.singleTestDurationFormatter
            singleTestsMeasurementFormatter.locale = locale
            let filesReports = files.compactMap { file in
                file.report(testResults: testResults,
                            formatter: singleTestsMeasurementFormatter)
            }
            return filesReports.joined(separator: "\n\n")
        case .count:
            let numberFormatter = NumberFormatter.testsCountFormatter
            numberFormatter.locale = locale
            let totalTestsMeasurementFormatter = MeasurementFormatter.totalTestsDurationFormatter
            totalTestsMeasurementFormatter.locale = locale
            let tests = files.flatMap { $0.repeatableTests.filtered(testResults: testResults) }
            let count = tests.count
            let duration = tests.totalDuration
            let addDuration = testResults != [.skipped] // don't add 0ms duration if requested only skipped tests
            return [
                numberFormatter.string(from: NSNumber(value: count)) ?? String(count),
                addDuration ? totalTestsMeasurementFormatter.string(from: duration).wrappedInBrackets : nil
            ]
                .compactMap{ $0 }
                .joined(separator: " ")
        }
    }
}

extension DBXCReportModel.Module.File {
    func report(testResults: [DBXCReportModel.Module.File.RepeatableTest.Test.Status],
                formatter: MeasurementFormatter) -> String? {
        let tests = repeatableTests.filtered(testResults: testResults).sorted { $0.name < $1.name }
        
        guard !tests.isEmpty else {
            return nil
        }
        
        var rows = tests
            .sorted { $0.name < $1.name }
            .map { test in
                test.report(formatter: formatter)
            }
        
        rows.insert(name, at: 0)
        
        return rows.joined(separator: "\n")
    }
}

fileprivate extension DBXCReportModel.Module.File.RepeatableTest {
    func report(formatter: MeasurementFormatter) -> String {
        [
            combinedStatus.icon,
            name
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
    static var singleTestDurationFormatter: MeasurementFormatter {
        let formatter = MeasurementFormatter()
        formatter.unitOptions = [.providedUnit]
        formatter.numberFormatter.maximumFractionDigits = 0
        return formatter
    }
    
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
