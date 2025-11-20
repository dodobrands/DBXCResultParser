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

    @Flag
    public var verbose: Bool = false

    public func run() async throws {
        Logger.verbose = verbose

        let xcresultPath = URL(fileURLWithPath: xcresultPath)
        let testsPath = URL(fileURLWithPath: testsPath)

        let report = try await Report(xcresultPath: xcresultPath)

        let formatter = SonarFormatter()
        let result = try formatter.format(report: report, testsPath: testsPath)

        Logger.logInfo(result)
    }
}
