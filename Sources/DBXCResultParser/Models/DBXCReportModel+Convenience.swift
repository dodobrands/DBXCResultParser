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
    /// Coverage data for targets specified in `excludingCoverageNames` will be excluded from the report.
    ///
    /// - Parameters:
    ///   - xcresultPath: The file URL of the `.xcresult` file to parse.
    ///   - excludingCoverageNames: An array of strings representing the names of the targets to be excluded
    ///                             from the code coverage report. Defaults to an empty array, meaning no
    ///                             targets will be excluded.
    /// - Throws: An error if the `.xcresult` file cannot be parsed.
    public init(
        xcresultPath: URL,
        excludingCoverageNames: [String] = []
    ) throws {

        let actionsInvocationRecordDTO = try ActionsInvocationRecordDTO(from: xcresultPath)

        let actionTestPlanRunSummariesDTO = try ActionTestPlanRunSummariesDTO(
            from: xcresultPath,
            refId: actionsInvocationRecordDTO.testsRefId
        )

        // Attempt to parse the code coverage data from the xcresult file, excluding specified targets.
        let coverageDTOs = try? [CoverageDTO](from: xcresultPath)
            .filter { !excludingCoverageNames.contains($0.name) }

        if let warningCount = actionsInvocationRecordDTO.metrics.warningCount?._value {
            self.warningCount = Int(warningCount)
        } else {
            self.warningCount = nil
        }

        let coverages = coverageDTOs?.map { Module.Coverage(from: $0) }

        var modules = Set<Module>()

        try actionTestPlanRunSummariesDTO.summaries._values.forEach { value1 in
            try value1.testableSummaries._values.forEach { value2 in
                let modulename = value2.name._value
                var module =
                    modules[modulename]
                    ?? DBXCReportModel.Module(
                        name: modulename,
                        files: [],
                        coverage: coverages?.forModule(named: modulename)
                    )
                try value2.tests._values.forEach { value3 in
                    try value3.subtests?._values.forEach { value4 in
                        try value4.subtests?._values.forEach { value5 in
                            let filename = value5.name._value
                            var file =
                                module.files[filename]
                                ?? .init(
                                    name: filename,
                                    repeatableTests: [])
                            try value5.subtests?._values.forEach { value6 in
                                let testname = value6.name._value
                                var repeatableTest =
                                    file.repeatableTests[testname]
                                    ?? DBXCReportModel.Module.File.RepeatableTest(
                                        name: testname,
                                        tests: []
                                    )
                                let test = try DBXCReportModel.Module.File.RepeatableTest.Test(
                                    value6, xcresultPath: xcresultPath)
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
}
