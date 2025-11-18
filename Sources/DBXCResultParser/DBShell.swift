//
//  DBShell.swift
//
//
//  Created by Алексей Берёзка on 28.12.2021.
//

import Foundation
import Subprocess

public actor DBShell {
    public static let shared = DBShell()

    private init() {}

    @discardableResult
    public func execute(_ executable: String, arguments: [String] = []) async throws -> String {
        let result = try await run(
            .name(executable),
            arguments: .init(arguments),
            output: .string(limit: 10 * 1024 * 1024),  // 10MB limit
            error: .string(limit: 10 * 1024 * 1024)  // 10MB limit for stderr
        )

        // Check if process exited successfully
        guard case .exited(let code) = result.terminationStatus, code == 0 else {
            let errorOutput = result.standardError ?? ""
            throw ShellError.processFailed(exitCode: result.terminationStatus, error: errorOutput)
        }

        return result.standardOutput?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            ?? ""
    }
}

enum ShellError: Error {
    case processFailed(exitCode: TerminationStatus, error: String)
}
