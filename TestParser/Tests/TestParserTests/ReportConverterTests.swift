//
//  ReportConverterTests.swift
//  
//
//  Created by Алексей Берёзка on 30.12.2021.
//

import Foundation
import XCTest
@testable import TestParser

class ReportConverterTests: XCTestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
    }
    
    func test() throws {
        let xcresultPath = try XCTUnwrap(ReportSeeker.seek(in: TestsConstants.resourcesPath).first)
        let overview = try ReportConverter.convert(xcresultPath: xcresultPath)
        _ = try ReportConverter.convertDetailed(xcresultPath: xcresultPath, refId: overview.testsRefID())
    }
}
