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
    var resourcesPath: URL!
    var resultPath: URL!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        resourcesPath = try XCTUnwrap(TestsConstants.resourcesPath)
        resultPath = resourcesPath.appendingPathComponent("report.json")
    }
    
    override func tearDownWithError() throws {
        try FileManager.default.removeItem(atPath: resultPath.relativePath)
        try super.tearDownWithError()
    }
    
    func test() throws {
        let sourcePath = try XCTUnwrap(ReportSeeker.seek(in: resourcesPath).first)
        try ReportConverter.convert(sourcePath: sourcePath, resultPath: resultPath)
        XCTAssertTrue(FileManager.default.fileExists(atPath: resultPath.relativePath))
    }
}
