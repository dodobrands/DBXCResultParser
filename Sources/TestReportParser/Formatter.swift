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
                    duration: filters.slowTestsDuration
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
    private func reportIcons(duration: Duration?) -> String {
        [
            combinedStatus.icon,
            duration.flatMap { slowIcon($0) }
        ]
            .compactMap { $0 }
            .joined(separator: "")
    }
    
    private func slowIcon(_ duration: Duration) -> String? {
        isSlow(duration) ? "🕢" : nil
    }
    
    private func reportDuration(with formatter: MeasurementFormatter) -> String {
        formatter.string(
            from: averageDuration
        ).wrappedInBrackets
    }
    
    private func slowReportDuration(
        with formatter: MeasurementFormatter,
        duration: Duration
    ) -> String? {
        guard isSlow(duration) else {
            return nil
        }
        return reportDuration(with: formatter)
    }
    
    func reportRow(with formatter: MeasurementFormatter, duration: Duration?) -> String {
        [
            reportIcons(duration: duration),
            duration.flatMap { slowReportDuration(with:formatter, duration: $0) },
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
    static var testsDurationFormatter: MeasurementFormatter {
        let formatter = MeasurementFormatter()
        formatter.unitOptions = [.providedUnit]
        formatter.numberFormatter.maximumFractionDigits = 0
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
