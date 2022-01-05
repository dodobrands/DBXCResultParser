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
    enum Error: Swift.Error {
        case missingDetailedReport
    }
}

public enum TestResult: String {
    case failure = "Failure"
    case success = "Success"
}

extension Parser {
    public enum Filter: String {
        case skipped = "skipped"
        case failed = "failed"
        case mixed = "mixed"
        case succeeded = "succeeded"
    }
    
    public enum Format: String {
        case list
        case count
    }
}