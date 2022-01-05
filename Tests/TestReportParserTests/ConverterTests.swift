//
//  ConverterTests.swift
//  
//
//  Created by Алексей Берёзка on 30.12.2021.
//

import Foundation
import XCTest
@testable import TestReportParser

class ConverterTests: XCTestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
    }
    
    func test() throws {
        let xcresultPath = try TestsConstants.unitTestsReportPath
        let overview = try Converter.convert(xcresultPath: xcresultPath)
        _ = try Converter.convertDetailed(xcresultPath: xcresultPath, refId: overview.testsRefID())
    }
}
