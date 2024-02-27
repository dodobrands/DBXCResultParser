//
//  DTO+Helpers.swift
//  
//
//  Created by Алексей Берёзка on 30.12.2021.
//

import Foundation

extension ActionsInvocationRecordDTO {
    init(from xcresultPath: URL) throws {
        let result = try DBShell.execute("xcrun xcresulttool get --path \(xcresultPath.relativePath) --format json")
        let data = try result.data(using: .utf8) ?! UnwrapError.valueIsNil
        self = try JSONDecoder().decode(ActionsInvocationRecordDTO.self, from: data)
    }
}

extension ActionTestPlanRunSummariesDTO {
    init(from xcresultPath: URL, refId: String? = nil) throws {
        let refId = try (refId ?? ActionsInvocationRecordDTO(from: xcresultPath).testsRefId)
        let result = try DBShell.execute("xcrun xcresulttool get --path \(xcresultPath.relativePath) --format json --id \(refId)")
        let data = try result.data(using: .utf8) ?! UnwrapError.valueIsNil
        self = try JSONDecoder().decode(ActionTestPlanRunSummariesDTO.self, from: data)
    }
}

extension ActionTestSummaryDTO {
    init(from xcresultPath: URL, refId: String? = nil) throws {
        let refId = try (refId ?? ActionsInvocationRecordDTO(from: xcresultPath).testsRefId)
        let result = try DBShell.execute("xcrun xcresulttool get --path \(xcresultPath.relativePath) --format json --id \(refId)")
        let data = try result.data(using: .utf8) ?! UnwrapError.valueIsNil
        self = try JSONDecoder().decode(ActionTestSummaryDTO.self, from: data)
    }
}

extension Array where Element == CoverageDTO {
    init(from xcresultPath: URL) throws {
        let result = try DBShell.execute("xcrun xccov view --report --only-targets --json \(xcresultPath.relativePath)")
        let data = try result.data(using: .utf8) ?! UnwrapError.valueIsNil
        self = try JSONDecoder().decode(Array<CoverageDTO>.self, from: data)
    }
}

infix operator ?!: NilCoalescingPrecedence

/// Throws the right hand side error if the left hand side optional is `nil`.
func ?!<T>(value: T?, error: @autoclosure () -> Error) throws -> T {
    guard let value = value else {
        throw error()
    }
    return value
}

enum UnwrapError: Swift.Error {
    case valueIsNil
}
