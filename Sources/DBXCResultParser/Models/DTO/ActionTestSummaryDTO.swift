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
}

extension ActionTestSummaryDTO {
    struct SkipNoticeSummary: Decodable {
        let message: MessageDTO
    }
}

extension ActionTestSummaryDTO.SkipNoticeSummary {
    struct MessageDTO: Decodable {
        let _value: String
    }
}

extension ActionTestSummaryDTO {
    struct FailureSummaries: Decodable {
        let _values: [ValueDTO]
    }
}

extension ActionTestSummaryDTO.FailureSummaries {
    struct ValueDTO: Decodable {
        let message: MessageDTO
    }
}

extension ActionTestSummaryDTO.FailureSummaries {
    struct MessageDTO: Decodable {
        let _value: String
    }
}

extension ActionTestSummaryDTO {
    var message: String? {
        skipNoticeSummary?.message._value ?? failureSummaries?._values.map { $0.message._value }.first
    }
}
