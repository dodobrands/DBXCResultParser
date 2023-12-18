//
//  DBXCReportModel+Convenience.swift
//  
//
//  Created by Aleksey Berezka on 15.12.2023.
//

import Foundation

extension DBXCReportModel {
    /// Initializes a new instance of the `DBXCReportModel` using the provided `xcresultPath`.
    /// The initialization process involves parsing the `.xcresult` file to extract various reports.
    ///
    /// - Parameter xcresultPath: The file URL of the `.xcresult` file to parse.
    /// - Throws: An error if the `.xcresult` file cannot be parsed or if required data is missing.
    public init(xcresultPath: URL) throws {
        // Parse the overview report from the xcresult file, which contains general test execution information.
        let overviewReport = try OverviewReportDTO(from: xcresultPath)
        
        // Parse the detailed report using the reference ID obtained from the overview report.
        // This report provides a more granular look at the test results, including individual test cases.
        let detailedReport = try DetailedReportDTO(from: xcresultPath,
                                                   refId: overviewReport.testsRefId)
        
        // Attempt to parse the code coverage data from the xcresult file.
        // It excludes any coverage data related to test helpers and test cases themselves.
        let coverageDTOs = try? Array<CoverageDTO>(from: xcresultPath)
            .filter { !$0.name.contains("TestHelpers") && !$0.name.contains("Tests") }
        
        self = try DBXCReportModel(
            overviewReportDTO: overviewReport,
            detailedReportDTO: detailedReport,
            coverageDTOs: coverageDTOs ?? []
        )
    }
}
