//
//  DBXCTextFormatter.swift
//  
//
//  Created by Алексей Берёзка on 31.12.2021.
//

import Foundation
import DBXCResultParser
import DBXCResultParser_TextFormatter
import ArgumentParser

@main
public class DBXCTextFormatterExecutable: ParsableCommand {
    public required init() { }
    
    @Option(help: "Path to .xcresult")
    public var xcresultPath: String
    
    @Option(help: "Result format")
    public var format: DBXCTextFormatter.Format = .list
    
    /// /// The locale to use for formatting numbers and measurements
    @Option(help: "Locale to use for numbers and measurements formatting (default: system)")
    public var locale: Locale?
    
    @Option(help: "Test statutes to include in report, comma separated")
    public var include: String = DBXCReportModel.Module.File.RepeatableTest.Test.Status.allCases.map { $0.rawValue }.joined(separator: ",")
    
    public func run() throws {
        let xcresultPath = URL(fileURLWithPath: xcresultPath)
        
        let report = try DBXCReportModel(xcresultPath: xcresultPath)
        
        let include = include.split(separator: ",")
            .compactMap { DBXCReportModel.Module.File.RepeatableTest.Test.Status(rawValue: String($0)) }
        
        let formatter = DBXCTextFormatter()
        
        let result = formatter.format(
            report,
            include: include,
            format: format,
            locale: locale
        )
        
        print(result)
    }
}

extension DBXCReportModel.Module.File {
    func report(testResults: [DBXCReportModel.Module.File.RepeatableTest.Test.Status],
                formatter: MeasurementFormatter) -> String? {
        let tests = repeatableTests.filtered(testResults: testResults).sorted { $0.name < $1.name }
        
        guard !tests.isEmpty else {
            return nil
        }
        
        var rows = tests
            .sorted { $0.name < $1.name }
            .map { test in
                test.report(formatter: formatter)
            }
        
        rows.insert(name, at: 0)
        
        return rows.joined(separator: "\n")
    }
}

fileprivate extension DBXCReportModel.Module.File.RepeatableTest {
    func report(formatter: MeasurementFormatter) -> String {
        [
            combinedStatus.icon,
            name
        ]
            .compactMap { $0 }
            .joined(separator: " ")
    }
}

extension String {
    var wrappedInBrackets: Self {
        "(" + self + ")"
    }
}

extension MeasurementFormatter {
    static var singleTestDurationFormatter: MeasurementFormatter {
        let formatter = MeasurementFormatter()
        formatter.unitOptions = [.providedUnit]
        formatter.numberFormatter.maximumFractionDigits = 0
        return formatter
    }
    
    static var totalTestsDurationFormatter: MeasurementFormatter {
        let formatter = MeasurementFormatter()
        formatter.unitOptions = [.naturalScale]
        formatter.numberFormatter.maximumFractionDigits = 0
        return formatter
    }
}

extension NumberFormatter {
    static var testsCountFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 0
        return formatter
    }
}

extension Locale: ExpressibleByArgument {
    public init?(argument: String) {
        self.init(identifier: argument)
    }
}

extension DBXCTextFormatter.Format: ExpressibleByArgument {
    public init?(argument: String) {
        self.init(rawValue: argument)
    }
}
