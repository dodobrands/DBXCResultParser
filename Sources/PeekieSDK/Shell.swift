import Foundation
import Logging
import Subprocess

class Shell {
    private static let logger = Logger(label: "com.peekie.shell")

    @discardableResult
    static func execute(_ executable: String, arguments: [String] = []) async throws -> String {
        logger.debug(
            "Executing command",
            metadata: [
                "executable": "\(executable)",
                "arguments": "\(arguments.joined(separator: " "))",
            ]
        )

        let result = try await run(
            .name(executable),
            arguments: .init(arguments),
            output: .string(limit: .max),
            error: .string(limit: .max)
        )

        // Check if process exited successfully
        guard case .exited(let code) = result.terminationStatus, code == 0 else {
            let errorOutput = result.standardError ?? ""
            let exitCode: String
            if case .exited(let exitCodeValue) = result.terminationStatus {
                exitCode = "\(exitCodeValue)"
            } else {
                exitCode = "\(result.terminationStatus)"
            }
            logger.debug(
                "Command failed",
                metadata: [
                    "executable": "\(executable)",
                    "exitCode": "\(exitCode)",
                    "error": "\(errorOutput.prefix(200))",
                ]
            )
            throw ShellError.processFailed(exitCode: result.terminationStatus, error: errorOutput)
        }

        let output =
            result.standardOutput?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            ?? ""
        logger.debug(
            "Command completed successfully",
            metadata: [
                "executable": "\(executable)",
                "outputLength": "\(output.count)",
            ]
        )
        return output
    }
}

enum ShellError: Error {
    case processFailed(exitCode: TerminationStatus, error: String)
}
