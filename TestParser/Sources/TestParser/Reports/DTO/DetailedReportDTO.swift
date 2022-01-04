//
//  E2ETestsReport.swift
//
//
//  Created by Станислав Карпенко on 14.12.2021.
//

import Foundation

struct DetailedReportDTO: Decodable {
    let summaries: Summaries
}

extension DetailedReportDTO {
    struct Summaries: Decodable {
        let _values: [Value]
    }
}

extension DetailedReportDTO.Summaries {
    struct Value: Decodable {
        let testableSummaries: TestableSummaries
    }
}

extension DetailedReportDTO.Summaries.Value {
    struct TestableSummaries: Decodable {
        let _values: [Value]
    }
}

extension DetailedReportDTO.Summaries.Value.TestableSummaries {
    struct Value: Decodable {
        let tests: Tests
        let name: StringValueDTO
    }
}

extension DetailedReportDTO.Summaries.Value.TestableSummaries.Value {
    struct Tests: Decodable {
        let _values: [Value]
    }
}

extension DetailedReportDTO.Summaries.Value.TestableSummaries.Value {
    struct Name: Decodable {
        let _value: String
    }
}

extension DetailedReportDTO.Summaries.Value.TestableSummaries.Value.Tests {
    struct Value: Decodable {
        let subtests: Subtests?
    }
}

extension DetailedReportDTO.Summaries.Value.TestableSummaries.Value.Tests.Value {
    struct Subtests: Decodable {
        let _values: [Value]
    }
}

extension DetailedReportDTO.Summaries.Value.TestableSummaries.Value.Tests.Value.Subtests {
    struct Value: Decodable {
        let subtests: Subtests?
    }
}

extension DetailedReportDTO.Summaries.Value.TestableSummaries.Value.Tests.Value.Subtests.Value {
    struct Subtests: Decodable {
        let _values: [Value]
    }
}

extension DetailedReportDTO.Summaries.Value.TestableSummaries.Value.Tests.Value.Subtests.Value.Subtests {
    struct Value: Decodable {
        let subtests: Subtests?
        let name: Name
    }
}

extension DetailedReportDTO.Summaries.Value.TestableSummaries.Value.Tests.Value.Subtests.Value.Subtests.Value {
    struct Subtests: Decodable {
        let _values: [Value]
    }
}

extension DetailedReportDTO.Summaries.Value.TestableSummaries.Value.Tests.Value.Subtests.Value.Subtests.Value {
    struct Name: Decodable {
        /// ActiveOrdersBadgeServiceSpec
        let _value: String
    }
}

extension DetailedReportDTO.Summaries.Value.TestableSummaries.Value.Tests.Value.Subtests.Value.Subtests.Value.Subtests {
    struct Value: Decodable {
        let duration: StringValueDTO
        /// ActiveOrdersBadgeServiceSpec\/ActiveOrdersBadgeService__badge_count__delivery_orders__should_be_skipped()
        let identifier: StringValueDTO
        /// ActiveOrdersBadgeService__badge_count__delivery_orders__should_be_skipped()
        let name: StringValueDTO
        let testStatus: StringValueDTO
    }
}

struct StringValueDTO: Decodable {
    let _value: String
}
