//
//  ReportConverterTests.swift
//  
//
//  Created by Алексей Берёзка on 30.12.2021.
//

import Foundation
import XCTest
@testable import TestReportParser

class ReportConverterTests: XCTestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
    }
    
    func test() throws {
        let xcresultPath = try TestsConstants.unitTestsReportPath
        let overview = try ReportConverter.convert(xcresultPath: xcresultPath)
        _ = try ReportConverter.convertDetailed(xcresultPath: xcresultPath, refId: overview.testsRefID())
    }
}
