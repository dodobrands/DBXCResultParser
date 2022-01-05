//
//  ShellTests.swift
//  
//
//  Created by Алексей Берёзка on 28.12.2021.
//

import Foundation
import XCTest
@testable import TestReportParser

class ShellTests: XCTestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
    }
    
    func test() throws {
        try XCTAssertEqual(Shell.execute("which swift"), "/usr/bin/swift")
    }
}
