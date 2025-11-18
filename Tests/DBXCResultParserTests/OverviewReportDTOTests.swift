//
//  ActionsInvocationRecordDTOTests.swift
//
//
//  Created by Алексей Берёзка on 30.12.2021.
//

import Foundation
import Testing

@testable import DBXCResultParser

@Suite
struct ActionsInvocationRecordDTOTests {

    @Test
    func test() throws {
        _ = try ActionsInvocationRecordDTO(from: Constants.testsReportPath)
    }
}
