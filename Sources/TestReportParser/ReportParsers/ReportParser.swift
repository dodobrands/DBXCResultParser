import Foundation

public class ReportParser {
    let report: ReportModel
    
    public init(xcresultPath: URL) throws {
        let overviewReport = try ReportConverter.convert(xcresultPath: xcresultPath)
        let detailedReport = try ReportConverter.convertDetailed(xcresultPath: xcresultPath, refId: overviewReport.testsRefID())
        report = try ReportModel(detailedReport)
    }

    public func parse(filters: [Filter] = [], format: Format) throws -> String {
        ReportFormatter.format(report, filters: filters, format: format)
    }
}

extension ReportParser {
    enum Error: Swift.Error {
        case missingDetailedReport
    }
}

public enum TestResult: String {
    case failure = "Failure"
    case success = "Success"
}

extension ReportParser {
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
