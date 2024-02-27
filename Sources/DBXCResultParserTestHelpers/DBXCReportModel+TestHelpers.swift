//
//  DBXCReportModel+TestHelpers.swift
//  
//
//  Created by Aleksey Berezka on 18.12.2023.
//

import Foundation
@testable import DBXCResultParser

extension DBXCReportModel {
    public static func testMake(
        modules: Set<Module> = [],
        warningCount: Int? = nil
    ) -> Self {
        .init(
            modules: modules, 
            warningCount: warningCount
        )
    }
}

extension DBXCReportModel.Module {
    public static func testMake(
        name: String = "", 
        files: Set<File> = [],
        coverage: Coverage = .testMake()
    ) -> Self {
        .init(name: name, files: files, coverage: coverage)
    }
}

extension DBXCReportModel.Module.Coverage {
    public static func testMake(
        name: String = "",
        coveredLines: Int = 0,
        totalLines: Int = 0,
        coverage: Double = 0.0
    ) -> Self {
        Self(name: name,
             coveredLines: coveredLines,
             totalLines: totalLines,
             coverage: coverage)
    }
}

extension DBXCReportModel.Module.File {
    public static func testMake(
        name: String = "", 
        repeatableTests: Set<RepeatableTest> = []
    ) -> Self {
        .init(name: name, repeatableTests: repeatableTests)
    }
}

extension DBXCReportModel.Module.File.RepeatableTest {
    public static func testMake(
        name: String = "",
        tests: [Test] = []
    ) -> Self {
        .init(name: name, tests: tests)
    }
    
    public static func failed(
        named name: String,
        times: Int = 1
    ) -> Self {
        let tests = Array(
            repeating: DBXCReportModel.Module.File.RepeatableTest.Test.testMake(status: .failure),
            count: times
        )
        return .testMake(name: name, tests: tests)
    }
    
    public static func succeeded(
        named name: String
    ) -> Self {
        .testMake(name: name, tests: [.testMake(status: .success)])
    }
    
    public static func skipped(
        named name: String
    ) -> Self {
        .testMake(name: name, tests: [.testMake(status: .skipped)])
    }
    
    public static func mixedFailedSucceeded(
        named name: String,
        failedTimes: Int = 1
    ) -> Self {
        let failedTests = Array(
            repeating: DBXCReportModel.Module.File.RepeatableTest.Test.testMake(status: .failure),
            count: failedTimes
        )
        return .testMake(name: name, tests: failedTests + [.testMake(status: .success)])
    }
}

extension DBXCReportModel.Module.File.RepeatableTest.Test {
    public static func testMake(
        status: Status = .success,
        duration: Measurement<UnitDuration> = .testMake(),
        message: String? = nil
    ) -> Self {
        .init(
            status: status,
            duration: duration,
            message: message
        )
    }
}
