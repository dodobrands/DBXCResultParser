//
//  ReportModel+Convenience.swift
//  
//
//  Created by Aleksey Berezka on 15.12.2023.
//

import Foundation

extension ReportModel {
    public init(xcresultPath: URL) throws {
        let overviewReport = try OverviewReportDTO(from: xcresultPath)
        let detailedReport = try DetailedReportDTO(from: xcresultPath,
                                                   refId: overviewReport.testsRefId)
        let coverageDTOs = try? Array<CoverageDTO>(from: xcresultPath)
            .filter { !$0.name.contains("TestHelpers") && !$0.name.contains("Tests") }
        
        self = try ReportModel(
            overviewReportDTO: overviewReport,
            detailedReportDTO: detailedReport,
            coverageDTOs: coverageDTOs ?? []
        )
    }
}
