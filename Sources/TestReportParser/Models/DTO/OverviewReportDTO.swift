//
//  OverviewReportDTO.swift
//
//
//  Created by Mikhail Rubanov on 24.05.2021.
//

import Foundation

struct OverviewReportDTO: Codable {
    let actions: Actions
}

extension OverviewReportDTO {
    struct Actions: Codable {
        let _values: [Value]
    }
}

extension OverviewReportDTO.Actions {
    struct Value: Codable {
        let actionResult: ActionResult
    }
}

extension OverviewReportDTO.Actions.Value {
    struct ActionResult: Codable {
        let testsRef: StringReference?
    }
}

extension OverviewReportDTO {
    var testsRefId: String {
        get throws {
            let testRefs = actions._values.compactMap { $0.actionResult.testsRef }
            
            guard let testsRef = testRefs.first?.id._value else {
                throw Error.noTestRef
            }
            
            return testsRef
        }
    }
    
    enum Error: Swift.Error {
        case noTestRef
    }
}
