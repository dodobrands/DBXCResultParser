//
//  ActionTestSummaryDTO.swift
//
//
//  Created by Aleksey Berezka on 27.02.2024.
//

import Foundation

struct ActionTestSummaryDTO {
    let skipNoticeSummary: SkipNoticeSummary
}

extension ActionTestSummaryDTO {
    struct SkipNoticeSummary {
        let message: MessageDTO
    }
}

extension ActionTestSummaryDTO.SkipNoticeSummary {
    struct MessageDTO {
        let _value: String
    }
}
