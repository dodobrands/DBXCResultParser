import Foundation

public class Parser {
    public private(set) var report: ReportModel
    
    public init(xcresultPath: URL) throws {
        let overviewReport = try OverviewReportDTO(from: xcresultPath)
        let detailedReport = try DetailedReportDTO(from: xcresultPath,
                                                   refId: overviewReport.testsRefId)
        let coverageDTOs = try? Array<CoverageDTO>(from: xcresultPath)
            .filter { !$0.name.contains("TestHelpers") && !$0.name.contains("Tests") }
        
        report = try ReportModel(overviewReportDTO: overviewReport,
                                 detailedReportDTO: detailedReport,
                                 coverageDTOs: coverageDTOs ?? [])
    }

    public func parse(filters: [Filter] = [], format: Format) throws -> String {
        switch format {
        case .text(let format):
            return Formatter.format(report, filters: filters, format: format)
        }
    }
}

extension Parser {
    public enum Filter: Equatable {
        case skipped
        case failed
        case mixed
        case succeeded
        case slow(duration: Duration)
    }
    
    public enum Format {
        case text(format: TextFormat)
        
        public enum TextFormat {
            case list
            case count
        }
    }
}
