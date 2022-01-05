import Foundation

public class Parser {
    let report: ReportModel
    
    public init(xcresultPath: URL) throws {
        let overviewReport = try OverviewReportDTO(from: xcresultPath)
        let detailedReport = try DetailedReportDTO(from: xcresultPath,
                                                   refId: overviewReport.testsRefId)
        report = try ReportModel(detailedReport)
    }

    public func parse(filters: [Filter] = [], format: Format) throws -> String {
        Formatter.format(report, filters: filters, format: format)
    }
}

extension Parser {
    public enum Filter {
        case skipped
        case failed
        case mixed
        case succeeded
        case slow(duration: Duration)
    }
    
    public enum Format {
        case list
        case count
    }
}
