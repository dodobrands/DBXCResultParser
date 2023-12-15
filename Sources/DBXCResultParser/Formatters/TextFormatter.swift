//
//  TextFormatter.swift
//  
//
//  Created by Алексей Берёзка on 31.12.2021.
//

import Foundation

extension TextFormatter {
    public enum Format {
        case list
        case count
    }
}

class TextFormatter: FormatterProtocol {
    public let format: Format
    public let locale: Locale?
    
    public init(
        format: Format,
        locale: Locale? = nil
    ) {
        self.format = format
        self.locale = locale
    }
    
    public func format(
        _ report: ReportModel,
        testResults: [TestResult] = TestResult.allCases
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

extension Array where Element == ReportModel.Module.File.RepeatableTest {
    var totalDuration: Duration {
        assert(map { $0.totalDuration.unit }.elementsAreEqual)
        let value = map { $0.totalDuration.value }.sum()
        let unit = first?.totalDuration.unit ?? ReportModel.Module.File.RepeatableTest.Test.defaultDurationUnit
        return .init(value: value, unit: unit)
    }
}

extension ReportModel.Module.File {
    func report(testResults: [TestResult],
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

fileprivate extension ReportModel.Module.File.RepeatableTest {
    private func reportIcons() -> String {
        combinedStatus.icon
    }
    
    private func reportDuration(formatter: MeasurementFormatter, slowThresholdDuration: Duration) -> String {
        formatter.string(
            from: averageDuration.converted(to: slowThresholdDuration.unit)
        ).wrappedInBrackets
    }
    
    func report(formatter: MeasurementFormatter) -> String {
        [
            reportIcons(),
            name
        ]
            .compactMap { $0 }
            .joined(separator: " ")
    }
}

fileprivate extension ReportModel.Module.File.RepeatableTest.Test.Status {
    var icon: String {
        switch self {
        case .success:
            return "✅"
        case .failure:
            return "❌"
        case .skipped:
            return "⏭"
        case .mixed:
            return "⚠️"
        case .expectedFailure:
            return "🤡"
        case .unknown:
            return "🤷"
        }
    }
}

extension Set where Element == ReportModel.Module.File.RepeatableTest {
    func filtered(testResults: [TestResult]) -> Set<Element> {
        guard !testResults.isEmpty else {
            return self
        }
        
        let results = testResults
            .flatMap { testResult -> Set<Element> in
                switch testResult {
                case .succeeded:
                    return self.succeeded
                case .failed:
                    return self.failed
                case .mixed:
                    return self.mixed
                case .skipped:
                    return self.skipped
                }
            }
        
        return Set(results)
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
