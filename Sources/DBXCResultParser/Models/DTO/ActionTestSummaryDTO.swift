//
//  ActionTestSummaryDTO.swift
//
//
//  Created by Aleksey Berezka on 27.02.2024.
//

import Foundation

struct ActionTestSummaryDTO: Decodable {
    let skipNoticeSummary: SkipNoticeSummary?
    let failureSummaries: FailureSummaries?
    let expectedFailures: ExpectedFailures?
}

extension ActionTestSummaryDTO {
    struct SkipNoticeSummary: Decodable {
        let message: MessageDTO
    }
}

extension ActionTestSummaryDTO {
    struct FailureSummaries: Decodable {
        let _values: [ValueDTO]
    }
}

extension ActionTestSummaryDTO.FailureSummaries {
    struct ValueDTO: Decodable {
        let message: ActionTestSummaryDTO.MessageDTO
    }
}

extension ActionTestSummaryDTO {
    struct ExpectedFailures: Decodable {
        let _values: [ValueDTO]
    }
}

extension ActionTestSummaryDTO.ExpectedFailures {
    struct ValueDTO: Decodable {
        let failureSummary: FailureSummary
    }
}

extension ActionTestSummaryDTO.ExpectedFailures.ValueDTO {
    struct FailureSummary: Decodable {
        let message: ActionTestSummaryDTO.MessageDTO
    }
}

extension ActionTestSummaryDTO {
    var message: String? {
        let message = skipNoticeSummary?.message ?? failureSummaries?._values.first?.message ?? expectedFailures?._values.first?.failureSummary.message
        return message?._value
    }
}

extension ActionTestSummaryDTO {
    struct MessageDTO: Decodable {
        let _value: String
    }
}
