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
        let files = report.modules.flatMap { $0.files }
        let filesSorted = Array(files).sorted { $0.name < $1.name }
        var count = 0
        var filesFormatted = [String]()
        let formatter = MeasurementFormatter.testsDurationFormatter
        filesSorted.forEach { file in
            var fileRows = [String]()
            
            let filteredRepeatableTests = file.repeatableTests.filtered(filters: filters)
            
            let sortedRepeatableTests = filteredRepeatableTests.sorted { $0.name < $1.name }
            var formattedRepeatableTestEntries = [String]()
            sortedRepeatableTests.forEach { repeatableTest in
                let reportTestRow = repeatableTest.reportRow(
                    with: formatter,
                    slowTestsThreshold: filters.slowThreshold
                )
                formattedRepeatableTestEntries.append(reportTestRow)
            }

            if !formattedRepeatableTestEntries.isEmpty {
                // header
                fileRows.append(file.name)
                fileRows.append(contentsOf: formattedRepeatableTestEntries)
                let fileRowsJoined = fileRows.joined(separator: "\n")
                filesFormatted.append(fileRowsJoined)
                count += filteredRepeatableTests.count
            }
        }
        
        switch format {
        case .list:
            return filesFormatted.joined(separator: "\n\n")
        case .count:
            return String(count)
        }
    }
}

fileprivate extension ReportModel.Module.File.RepeatableTest {
    private func reportIcons(slowTestsThreshold: Double?) -> String {
        [
            combinedStatus.icon,
            slowTestsThreshold.flatMap { slowIcon($0) }
        ]
            .compactMap { $0 }
            .joined(separator: "")
    }
    
    private func isSlow(_ slowTestsThreshold: Double) -> Bool {
        averageDuration >= slowTestsThreshold
    }
    
    private func slowIcon(_ slowTestsThreshold: Double) -> String? {
        isSlow(slowTestsThreshold) ? "🕢" : nil
    }
    
    private func reportDuration(with formatter: MeasurementFormatter) -> String {
        formatter.string(
            from: Measurement(
                value: averageDuration,
                unit: .init(symbol: "ms")
            )
        ).wrappedInBrackets
    }
    
    private func slowReportDuration(
        with formatter: MeasurementFormatter,
        slowTestsThreshold: Double
    ) -> String? {
        guard isSlow(slowTestsThreshold) else {
            return nil
        }
        return reportDuration(with: formatter)
    }
    
    func reportRow(with formatter: MeasurementFormatter, slowTestsThreshold: Double?) -> String {
        [
            reportIcons(slowTestsThreshold: slowTestsThreshold),
            slowTestsThreshold.flatMap { slowReportDuration(with:formatter, slowTestsThreshold: $0) },
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
            case .slow(let milliseconds):
                return self.slow(milliseconds)
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
    static var testsDurationFormatter: MeasurementFormatter {
        let formatter = MeasurementFormatter()
        formatter.unitStyle = .long
        formatter.numberFormatter.maximumFractionDigits = 0
        return formatter
    }
}

extension Array where Element == Parser.Filter {
    var slowThreshold: Double? {
        var threshold: Double?
        
        forEach { filter in
            switch filter {
            case .slow(let milliseconds):
                threshold = milliseconds
            default:
                return
            }
        }
        
        return threshold
    }
}
