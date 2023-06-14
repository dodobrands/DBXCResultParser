//
//  ReportModel.swift
//  
//
//  Created by Алексей Берёзка on 31.12.2021.
//

import Foundation

public typealias Duration = Measurement<UnitDuration>

public struct ReportModel {
    public let modules: Set<Module>
    public private(set) var warningCount: Int?
}

extension ReportModel {
    public struct Module: Hashable {
        public let name: String
        public internal(set) var files: Set<File>
        public let coverage: Coverage?
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(name)
        }
        
        public static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.name == rhs.name
        }
    }
}

extension ReportModel.Module {
    public struct Coverage: Equatable {
        public let name: String
        public let coveredLines: Int
        public let totalLines: Int
        public let coverage: Double
        
        init(name: String,
             coveredLines: Int,
             totalLines: Int,
             coverage: Double) {
            self.name = name
            self.coveredLines = coveredLines
            self.totalLines = totalLines
            self.coverage = coverage
        }
        
        init(from dto: CoverageDTO) {
            self.name = dto.name
            self.coveredLines = dto.coveredLines
            self.totalLines = dto.executableLines
            self.coverage = dto.lineCoverage
        }
    }
}

extension ReportModel.Module {
    public struct File: Hashable {
        public let name: String
        public internal(set) var repeatableTests: Set<RepeatableTest>
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(name)
        }
        
        public static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.name == rhs.name
        }
    }
}
extension ReportModel.Module.File {
    public struct RepeatableTest: Hashable {
        public let name: String
        public internal(set) var tests: [Test]
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(name)
        }
        
        public static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.name == rhs.name
        }
    }
}

extension ReportModel.Module.File.RepeatableTest {
    public struct Test {
        public let status: Status
        public let duration: Duration
    }
    
    var combinedStatus: Test.Status {
        let statuses = tests.map { $0.status }
        if statuses.elementsAreEqual {
            return statuses.first ?? .success
        } else {
            return .mixed
        }
    }
    
    var averageDuration: Duration {
        assert(tests.map { $0.duration.unit }.elementsAreEqual)
        
        let unit = tests.first?.duration.unit ?? Test.defaultDurationUnit
        
        return .init(
            value: tests.map { $0.duration.value }.average(),
            unit: unit
        )
    }
    
    var totalDuration: Duration {
        assert(tests.map { $0.duration.unit }.elementsAreEqual)
        let value = tests.map { $0.duration.value }.sum()
        let unit = tests.first?.duration.unit ?? Test.defaultDurationUnit
        return .init(value: value, unit: unit)
    }
    
    func isSlow(_ duration: Duration) -> Bool {
        let averageDuration = averageDuration
        let duration = duration.converted(to: averageDuration.unit)
        return averageDuration >= duration
    }
}

extension ReportModel.Module.File.RepeatableTest.Test {
    public enum Status: Equatable {
        case success
        case failure
        case expectedFailure
        case skipped
        case mixed
        case unknown(rawValue: String)
    }
}

extension ReportModel {
    init(overviewReportDTO: OverviewReportDTO,
         detailedReportDTO: DetailedReportDTO,
         coverageDTOs: [CoverageDTO]) throws {
        
        if let warningCount = overviewReportDTO.metrics.warningCount?._value {
            self.warningCount = Int(warningCount)
        }
        
        let filteredCoverages = coverageDTOs
            .map { Module.Coverage(from: $0)}
            .filter { !$0.name.contains("TestHelpers") && !$0.name.contains("Tests") }
        var modules = Set<Module>()
        
        func findCoverage(for moduleName: String, coverageModels: [Module.Coverage]) -> Module.Coverage? {
            coverageModels.first { $0.name.split(separator: ".")[0] + "Tests" == moduleName }
        }
        
        try detailedReportDTO.summaries._values.forEach { value1 in
            try value1.testableSummaries._values.forEach { value2 in
                let modulename = value2.name._value
                var module = modules[modulename] ?? .init(name: modulename,
                                                          files: [],
                                                          coverage: findCoverage(for: modulename,
                                                                                 coverageModels: filteredCoverages))
                try value2.tests._values.forEach { value3 in
                    try value3.subtests?._values.forEach { value4 in
                        try value4.subtests?._values.forEach { value5 in
                            let filename = value5.name._value
                            var file = module.files[filename] ?? .init(name: filename,
                                                                       repeatableTests: [])
                            try value5.subtests?._values.forEach { value6 in
                                let testname = value6.name._value
                                var repeatableTest = file.repeatableTests[testname] ?? .init(name: testname,
                                                                                             tests: [])
                                let test = try ReportModel.Module.File.RepeatableTest.Test(value6)
                                repeatableTest.tests.append(test)
                                file.repeatableTests.update(with: repeatableTest)
                            }
                            module.files.update(with: file)
                        }
                    }
                }
                
                modules.update(with: module)
            }
        }
        
        self.modules = modules
    }
    
    public var totalCoverage: Double? {
        let coverages = modules.map { $0.coverage }.compactMap { $0 }
        guard coverages.count > 0 else { return nil }
        
        let totalLines = coverages.reduce(into: 0) { $0 += $1.totalLines }
        let totalCoveredLines = coverages.reduce(into: 0) { $0 += $1.coveredLines }
        
        guard totalLines != 0 else { return 0.0 }
        return Double(totalCoveredLines) / Double(totalLines)
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

extension Set where Element == ReportModel.Module.File.RepeatableTest {
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
    
    func slow(_ duration: Duration) -> Self {
        filter { $0.isSlow(duration) }
    }
}

extension ReportModel.Module.File.RepeatableTest.Test {
    init(_ test: DetailedReportDTO.Summaries.Value.TestableSummaries.Value.Tests.Value.Subtests.Value.Subtests.Value.Subtests.Value) throws {
        switch test.testStatus._value {
        case "Success":
            status = .success
        case "Failure":
            status = .failure
        case "Skipped":
            status = .skipped
        case "Expected Failure":
            status = .expectedFailure
        default:
            status = .unknown(rawValue: test.testStatus._value)
        }
        
        guard let duration = Double(test.duration._value) else {
            throw Error.invalidDuration(duration: test.duration._value)
        }
        
        self.duration = .init(value: duration * 1000, unit: Self.defaultDurationUnit)
    }
    
    enum Error: Swift.Error {
        case invalidDuration(duration: String)
    }
    
    static let defaultDurationUnit = UnitDuration.milliseconds
}

extension Array where Element: Equatable {
    var elementsAreEqual: Bool {
        dropFirst().allSatisfy { $0 == first }
    }
}

extension Set where Element == ReportModel.Module.File {
    subscript(_ name: String) -> Element? {
        first { $0.name == name }
    }
}

extension Set where Element == ReportModel.Module.File.RepeatableTest {
    subscript(_ name: String) -> Element? {
        first { $0.name == name }
    }
}

extension Set where Element == ReportModel.Module {
    subscript(_ name: String) -> Element? {
        first { $0.name == name }
    }
}
