//
//  ReportFormatter.swift
//  
//
//  Created by Алексей Берёзка on 31.12.2021.
//

import Foundation

class ReportFormatter {
    static func format(_ report: ReportModel,
                       filters: [ReportParser.Filter] = [],
                       format: ReportParser.Format) -> String {
        let filesSorted = Array(report.files).sorted { $0.name < $1.name }
        var count = 0
        var filesFormatted = [String]()
        filesSorted.forEach { file in
            var fileRows = [String]()
            
            let filteredRepeatableTests = file.repeatableTests.filtered(filters: filters)
            
            let sortedRepeatableTests = filteredRepeatableTests.sorted { $0.name < $1.name }
            var formattedRepeatableTestEntries = [String]()
            sortedRepeatableTests.forEach { repeatableTest in
                let data = [
                    repeatableTest.combinedStatus.icon,
                    repeatableTest.name
                ]
                let formattedRepeatableTestEntry = data.joined(separator: " ")
                formattedRepeatableTestEntries.append(formattedRepeatableTestEntry)
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

fileprivate extension ReportModel.File.RepeatableTest.Test.Status {
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

extension Set where Element == ReportModel.File.RepeatableTest {
    func filtered(filters: [ReportParser.Filter]) -> [Element] {
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
            }
        }
    }
}
