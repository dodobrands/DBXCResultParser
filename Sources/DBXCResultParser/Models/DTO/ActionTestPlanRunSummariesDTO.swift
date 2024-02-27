//
//  ActionTestPlanRunSummariesDTO.swift
//
//
//  Created by Станислав Карпенко on 14.12.2021.
//

import Foundation

/// This report provides a more granular look at the test results, including individual test cases.
struct ActionTestPlanRunSummariesDTO: Decodable {
    let summaries: Summaries
}

extension ActionTestPlanRunSummariesDTO {
    struct Summaries: Decodable {
        let _values: [Value]
    }
}

extension ActionTestPlanRunSummariesDTO.Summaries {
    struct Value: Decodable {
        let testableSummaries: TestableSummaries
    }
}

extension ActionTestPlanRunSummariesDTO.Summaries.Value {
    struct TestableSummaries: Decodable {
        let _values: [Value]
    }
}

extension ActionTestPlanRunSummariesDTO.Summaries.Value.TestableSummaries {
    struct Value: Decodable {
        let tests: Tests
        let name: StringValueDTO
    }
}

extension ActionTestPlanRunSummariesDTO.Summaries.Value.TestableSummaries.Value {
    struct Tests: Decodable {
        let _values: [Value]
    }
}

extension ActionTestPlanRunSummariesDTO.Summaries.Value.TestableSummaries.Value {
    struct Name: Decodable {
        let _value: String
    }
}

extension ActionTestPlanRunSummariesDTO.Summaries.Value.TestableSummaries.Value.Tests {
    struct Value: Decodable {
        let subtests: Subtests?
    }
}

extension ActionTestPlanRunSummariesDTO.Summaries.Value.TestableSummaries.Value.Tests.Value {
    struct Subtests: Decodable {
        let _values: [Value]
    }
}

extension ActionTestPlanRunSummariesDTO.Summaries.Value.TestableSummaries.Value.Tests.Value.Subtests {
    struct Value: Decodable {
        let subtests: Subtests?
    }
}

extension ActionTestPlanRunSummariesDTO.Summaries.Value.TestableSummaries.Value.Tests.Value.Subtests.Value {
    struct Subtests: Decodable {
        let _values: [Value]
    }
}

extension ActionTestPlanRunSummariesDTO.Summaries.Value.TestableSummaries.Value.Tests.Value.Subtests.Value.Subtests {
    struct Value: Decodable {
        let subtests: Subtests?
        let name: Name
    }
}

extension ActionTestPlanRunSummariesDTO.Summaries.Value.TestableSummaries.Value.Tests.Value.Subtests.Value.Subtests.Value {
    struct Subtests: Decodable {
        let _values: [Value]
    }
}

extension ActionTestPlanRunSummariesDTO.Summaries.Value.TestableSummaries.Value.Tests.Value.Subtests.Value.Subtests.Value {
    struct Name: Decodable {
        let _value: String
    }
}

extension ActionTestPlanRunSummariesDTO.Summaries.Value.TestableSummaries.Value.Tests.Value.Subtests.Value.Subtests.Value.Subtests {
    struct Value: Decodable {
        let duration: StringValueDTO
        let identifier: StringValueDTO
        let name: StringValueDTO
        let testStatus: StringValueDTO
        let summaryRef: StringReference?
    }
}
