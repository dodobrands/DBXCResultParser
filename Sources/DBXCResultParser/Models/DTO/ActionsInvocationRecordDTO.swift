//
//  ActionsInvocationRecordDTO.swift
//
//
//  Created by Mikhail Rubanov on 24.05.2021.
//

import Foundation

struct ActionsInvocationRecordDTO: Codable {
    let actions: Actions
    let metrics: Metrics
}

extension ActionsInvocationRecordDTO {
    struct Actions: Codable {
        let _values: [Value]
    }
}

extension ActionsInvocationRecordDTO.Actions {
    struct Value: Codable {
        let actionResult: ActionResult
    }
}

extension ActionsInvocationRecordDTO.Actions.Value {
    struct ActionResult: Codable {
        let testsRef: StringReference?
    }
}

extension ActionsInvocationRecordDTO {
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

extension ActionsInvocationRecordDTO {
    struct Metrics: Codable {
        let warningCount: WarningCount?
    }
}

extension ActionsInvocationRecordDTO.Metrics {
    struct WarningCount: Codable {
        let _value: String
    }
}
