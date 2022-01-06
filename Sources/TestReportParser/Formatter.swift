//
//  Formatter.swift
//  
//
//  Created by Алексей Берёзка on 31.12.2021.
//

import Foundation

class Formatter {
    static func format(_ report: ReportModel,
                       filters: [Parser.Filter] = [],
                       format: Parser.Format) -> String {
        let files = report.modules
            .flatMap { Array($0.files) }
            .sorted { $0.name < $1.name }
        
        switch format {
        case .list:
            let slowTestsDuration = filters.slowTestsDuration
            let singleTestsMeasurementFormatter = MeasurementFormatter.singleTestDurationFormatter
            let filesReports = files.compactMap { file in
                file.report(filters: filters,
                            formatter: singleTestsMeasurementFormatter,
                            slowTestsDuration: slowTestsDuration)
            }
            return filesReports.joined(separator: "\n\n")
        case .count:
            let numberFormatter = NumberFormatter.testsCountFormatter
            let totalTestsMeasurementFormatter = MeasurementFormatter.totalTestsDurationFormatter
            let tests = files.flatMap { $0.repeatableTests.filtered(filters: filters) }
            let count = tests.count
            let duration = tests.totalDuration
            let addDuration = filters != [.skipped] // don't add 0ms duration if requested only skipped tests
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
    func report(filters: [Parser.Filter],
                formatter: MeasurementFormatter,
                slowTestsDuration: Duration?) -> String? {
        let tests = repeatableTests.filtered(filters: filters).sorted { $0.name < $1.name }
        
        guard !tests.isEmpty else {
            return nil
        }
        
        var rows = tests
            .sorted { $0.name < $1.name }
            .map { test in
            test.report(
                formatter: formatter,
                slowThresholdDuration: slowTestsDuration
            )
        }
        
        rows.insert(name, at: 0)
        
        return rows.joined(separator: "\n")
    }
}

fileprivate extension ReportModel.Module.File.RepeatableTest {
    private func reportIcons(_ slowThresholdDuration: Duration?) -> String {
        [
            combinedStatus.icon,
            slowThresholdDuration.flatMap { slowIcon($0) }
        ]
            .compactMap { $0 }
            .joined(separator: "")
    }
    
    private func slowIcon(_ slowThresholdDuration: Duration) -> String? {
        isSlow(slowThresholdDuration) ? "🕢" : nil
    }
    
    private func reportDuration(formatter: MeasurementFormatter, slowThresholdDuration: Duration) -> String {
        formatter.string(
            from: averageDuration.converted(to: slowThresholdDuration.unit)
        ).wrappedInBrackets
    }
    
    private func slowReportDuration(
        formatter: MeasurementFormatter,
        slowThresholdDuration: Duration
    ) -> String? {
        guard isSlow(slowThresholdDuration) else {
            return nil
        }
        return reportDuration(formatter: formatter, slowThresholdDuration: slowThresholdDuration)
    }
    
    func report(formatter: MeasurementFormatter, slowThresholdDuration: Duration?) -> String {
        [
            reportIcons(slowThresholdDuration),
            slowThresholdDuration.flatMap { slowReportDuration(formatter:formatter, slowThresholdDuration: $0) },
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
        }
    }
}

extension Set where Element == ReportModel.Module.File.RepeatableTest {
    func filtered(filters: [Parser.Filter]) -> [Element] {
        guard !filters.isEmpty else {
            return Array(self)
        }
        
        return filters
            .flatMap { filter -> Set<Element> in
            switch filter {
            case .succeeded:
                return self.succeeded
            case .failed:
                return self.failed
            case .mixed:
                return self.mixed
            case .skipped:
                return self.skipped
            case .slow(let duration):
                return self.slow(duration)
            }
        }
    }
}

extension String {
    var wrappedInBrackets: Self {
        "[" + self + "]"
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

extension Array where Element == Parser.Filter {
    var slowTestsDuration: Duration? {
        var duration: Duration?
        
        forEach { filter in
            switch filter {
            case .slow(let value):
                duration = value
            default:
                return
            }
        }
        
        return duration
    }
}
