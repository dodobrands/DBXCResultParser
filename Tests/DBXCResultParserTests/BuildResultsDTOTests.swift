//
//  BuildResultsDTOTests.swift
//
//
//  Created on 18.11.2025.
//

import Foundation
import Testing

@testable import DBXCResultParser

@Suite
struct BuildResultsDTOTests {

    @Test
    func test_buildResultsDtoParse_withWarningCount() throws {
        let json = """
            {
                "warningCount": 5
            }
            """
        let data = json.data(using: .utf8)!
        let dto = try JSONDecoder().decode(BuildResultsDTO.self, from: data)
        #expect(dto.warningCount == 5)
    }

    @Test
    func test_buildResultsDtoParse_withoutWarningCount() throws {
        let json = """
            {
                "actionTitle": "Build"
            }
            """
        let data = json.data(using: .utf8)!
        let dto = try JSONDecoder().decode(BuildResultsDTO.self, from: data)
        #expect(dto.warningCount == nil)
    }

    @Test
    func test_buildResultsDtoParse_zeroWarningCount() throws {
        let json = """
            {
                "warningCount": 0
            }
            """
        let data = json.data(using: .utf8)!
        let dto = try JSONDecoder().decode(BuildResultsDTO.self, from: data)
        #expect(dto.warningCount == 0)
    }
}
