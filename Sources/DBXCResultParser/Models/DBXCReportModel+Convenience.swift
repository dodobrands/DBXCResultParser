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
    ) async throws {

        let actionsInvocationRecordDTO = try await ActionsInvocationRecordDTO(from: xcresultPath)

        let actionTestPlanRunSummariesDTO = try await ActionTestPlanRunSummariesDTO(
            from: xcresultPath,
            refId: try actionsInvocationRecordDTO.testsRefId
        )

        // Attempt to parse the code coverage data from the xcresult file, excluding specified targets.
        let coverageDTOs = try? await [CoverageDTO](from: xcresultPath)
            .filter { !excludingCoverageNames.contains($0.name) }

        if let warningCount = actionsInvocationRecordDTO.metrics.warningCount?._value {
            self.warningCount = Int(warningCount)
        } else {
            self.warningCount = nil
        }

        let coverages = coverageDTOs?.map { Module.Coverage(from: $0) }

        var modules = Set<Module>()

        for value1 in actionTestPlanRunSummariesDTO.summaries._values {
            for value2 in value1.testableSummaries._values {
                let modulename = value2.name._value
                var module =
                    modules[modulename]
                    ?? DBXCReportModel.Module(
                        name: modulename,
                        files: [],
                        coverage: coverages?.forModule(named: modulename)
                    )
                for value3 in value2.tests._values {
                    if let subtests3 = value3.subtests {
                        for value4 in subtests3._values {
                            if let subtests4 = value4.subtests {
                                for value5 in subtests4._values {
                                    let filename = value5.name._value
                                    var file =
                                        module.files[filename]
                                        ?? .init(
                                            name: filename,
                                            repeatableTests: [])
                                    if let subtests5 = value5.subtests {
                                        for value6 in subtests5._values {
                                            let testname = value6.name._value
                                            var repeatableTest =
                                                file.repeatableTests[testname]
                                                ?? DBXCReportModel.Module.File.RepeatableTest(
                                                    name: testname,
                                                    tests: []
                                                )
                                            let test = try await DBXCReportModel.Module.File
                                                .RepeatableTest.Test(
                                                    value6, xcresultPath: xcresultPath)
                                            repeatableTest.tests.append(test)
                                            file.repeatableTests.update(with: repeatableTest)
                                        }
                                    }
                                    module.files.update(with: file)
                                }
                            }
                        }
                    }
                }

                modules.update(with: module)
            }
        }

        self.modules = modules
    }
}
