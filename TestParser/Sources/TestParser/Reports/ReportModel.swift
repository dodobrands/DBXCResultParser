//
//  ReportModel.swift
//  
//
//  Created by Алексей Берёзка on 31.12.2021.
//

import Foundation

struct ReportModel {
    let files: Set<File>
}

extension ReportModel {
    struct File: Hashable {
        let name: String
        var repeatableTests: Set<RepeatableTest>
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(name)
        }
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.name == rhs.name
        }
    }
}
extension ReportModel.File {
    struct RepeatableTest: Hashable {
        let name: String
        var tests: [Test]
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(name)
        }
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.name == rhs.name
        }
    }
}

extension ReportModel.File.RepeatableTest {
    struct Test {
        let status: Status
        let duration: Double
    }
    
    var combinedStatus: Test.Status {
        let satuses = tests.map { $0.status }
        if satuses.elementsAreEqual {
            return satuses.first ?? .success
        } else {
            return .mixed
        }
    }
}

extension ReportModel.File.RepeatableTest.Test {
    enum Status {
        case success
        case failure
        case skipped
        case mixed
    }
}

extension ReportModel {
    init(_ dto: DetailedReportDTO) throws {
        var files = Set<File>()      
        try dto.summaries._values.forEach { value1 in
            try value1.testableSummaries._values.forEach { value2 in
                try value2.tests._values.forEach { value3 in
                    try value3.subtests?._values.forEach { value4 in
                        try value4.subtests?._values.forEach { value5 in
                            let filename = value5.name._value
                            var file = files[filename] ?? File(name: filename,
                                                               repeatableTests: [])
                            try value5.subtests?._values.forEach { value6 in
                                let testname = value6.name._value
                                var repeatableTest = file.repeatableTests[testname] ?? .init(name: testname,
                                                                                             tests: [])
                                let test = try ReportModel.File.RepeatableTest.Test(value6)
                                repeatableTest.tests.append(test)
                                file.repeatableTests.update(with: repeatableTest)
                            }
                            files.update(with: file)
                        }
                    }
                }
            }
        }
        
        self.files = files
    }
}

extension ReportModel {
    enum Error: Swift.Error {
        case missingFilename(testName: String)
    }
}

fileprivate extension String {
    var testFilename: String? {
        split(separator: "/").first.map(String.init)
    }
}

extension Set where Element == ReportModel.File.RepeatableTest {
    var succeeded: Self {
        filter { $0.combinedStatus == .success }
    }
    
    var failed: Self {
        filter { $0.combinedStatus == .failure }
    }
    
    var skipped: Self {
        filter { $0.combinedStatus == .skipped }
    }
    
    var mixed: Self {
        filter { $0.combinedStatus == .mixed }
    }
}

extension ReportModel.File.RepeatableTest.Test {
    init(_ test: DetailedReportDTO.Summaries.Value.TestableSummaries.Value.Tests.Value.Subtests.Value.Subtests.Value.Subtests.Value) throws {
        switch test.testStatus._value {
        case "Success":
            status = .success
        case "Failure":
            status = .failure
        case "Skipped":
            status = .skipped
        default:
            throw Error.unknownStatus(status: test.testStatus._value)
        }
        
        guard let duration = Double(test.duration._value) else {
            throw Error.invalidDuration(duration: test.duration._value)
        }
        
        self.duration = duration
    }
    
    enum Error: Swift.Error {
        case unknownStatus(status: String)
        case invalidDuration(duration: String)
    }
}

extension Array where Element: Equatable {
    var elementsAreEqual: Bool {
        dropFirst().allSatisfy({ $0 == first })
    }
}

extension Set where Element == ReportModel.File {
    subscript(_ name: String) -> Element? {
        first { $0.name == name }
    }
}

extension Set where Element == ReportModel.File.RepeatableTest {
    subscript(_ name: String) -> Element? {
        first { $0.name == name }
    }
}
