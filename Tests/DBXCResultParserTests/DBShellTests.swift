//
//  ShellTests.swift
//
//
//  Created by Алексей Берёзка on 28.12.2021.
//

import Foundation
import Testing

@testable import DBXCResultParser

@Suite
struct DBShellTests {
    @Test
    func test() async throws {
        let result = try await DBShell.shared.execute("which", arguments: ["swift"])
        #expect(result == "/usr/bin/swift")
    }
}
