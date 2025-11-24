import ArgumentParser
import Foundation
import PeekieSDK

public struct Text: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "text",
        abstract: "Format test results as human-readable text"
    )

    public init() {}

    @Option(help: "Path to .xcresult")
    public var xcresultPath: String

    @Option(help: "Result format")
    public var format: TextFormatter.Format = .list

    /// The locale to use for formatting numbers and measurements
    @Option(
        help:
            "Locale identifier to use for numbers and measurements formatting (e.g., 'en-US', 'ru-RU'). If not provided, system locale is used."
    )
    public var locale: String?

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

        let localeValue: Locale
        if let localeString = locale {
            guard !localeString.isEmpty else {
                throw PeekieSDKError.invalidLocaleIdentifier(localeString)
            }
            let createdLocale = Locale(identifier: localeString)
            // Validate that the locale identifier is valid
            guard Locale.availableIdentifiers.contains(localeString) else {
                throw PeekieSDKError.invalidLocaleIdentifier(localeString)
            }
            localeValue = createdLocale
        } else {
            localeValue = Locale.current
        }

        let formatter = TextFormatter()

        let result = formatter.format(
            report,
            include: include,
            format: format,
            locale: localeValue
        )

        print(result)
    }
}

extension TextFormatter.Format: ExpressibleByArgument {
    public init?(argument: String) {
        self.init(rawValue: argument)
    }
}
