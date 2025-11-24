import ArgumentParser
import Foundation
import PeekieSDK

public struct Sonar: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "sonar",
        abstract: "Format test results as SonarQube Generic Test Execution XML"
    )

    public init() {}

    @Option(help: "Path to .xcresult")
    public var xcresultPath: String

    @Option(help: "Path to folder with tests")
    public var testsPath: String

    public func run() async throws {
        let xcresultPath = URL(fileURLWithPath: xcresultPath)
        let testsPath = URL(fileURLWithPath: testsPath)

        let report = try await Report(
            xcresultPath: xcresultPath,
            includeCoverage: false,
            includeWarnings: false
        )

        let formatter = SonarFormatter()
        let result = try formatter.format(report: report, testsPath: testsPath)

        print(result)
    }
}
