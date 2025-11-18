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
    func test() throws {
        let result = try DBShell.execute("which swift")
        #expect(result == "/usr/bin/swift")
    }
}
