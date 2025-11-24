import ArgumentParser
import Foundation
import PeekieSDK

public struct List: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "Format test results as human-readable list"
    )

    public init() {}

    @Argument(help: "Path to .xcresult")
    public var xcresultPath: String

    @Option(help: "Test statutes to include in report, comma separated")
    public var include: String = Report.Module.File.RepeatableTest.Test.Status.allCases.map {
        $0.rawValue
    }.joined(separator: ",")

    @Option(help: "Whether to parse and include code coverage data")
    public var includeCoverage: Bool = true

    @Option(help: "Whether to parse and include build warnings")
    public var includeWarnings: Bool = true

    public func run() async throws {
        let xcresultPath = URL(fileURLWithPath: xcresultPath)

        let report = try await Report(
            xcresultPath: xcresultPath,
            includeCoverage: includeCoverage,
            includeWarnings: includeWarnings
        )

        let include = include.split(separator: ",")
            .compactMap {
                Report.Module.File.RepeatableTest.Test.Status(rawValue: String($0))
            }

        let formatter = PeekieSDK.ListFormatter()

        let result = formatter.format(
            report,
            include: include
        )

        print(result)
    }
}
