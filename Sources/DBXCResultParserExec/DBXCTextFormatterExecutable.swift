import ArgumentParser
import DBXCResultParser
import Foundation

@main
public class DBXCTextFormatterExecutable: AsyncParsableCommand {
    public required init() {}

    @Option(help: "Path to .xcresult")
    public var xcresultPath: String

    @Option(help: "Result format")
    public var format: DBXCTextFormatter.Format = .list

    /// The locale to use for formatting numbers and measurements
    @Option(
        help:
            "Locale identifier to use for numbers and measurements formatting (e.g., 'en-US', 'ru-RU'). If not provided, system locale is used."
    )
    public var locale: String?

    @Option(help: "Test statutes to include in report, comma separated")
    public var include: String = DBXCReportModel.Module.File.RepeatableTest.Test.Status.allCases.map
    { $0.rawValue }.joined(separator: ",")

    public func run() async throws {
        let xcresultPath = URL(fileURLWithPath: xcresultPath)

        let report = try await DBXCReportModel(xcresultPath: xcresultPath)

        let include = include.split(separator: ",")
            .compactMap {
                DBXCReportModel.Module.File.RepeatableTest.Test.Status(rawValue: String($0))
            }

        let localeValue: Locale
        if let localeString = locale {
            guard !localeString.isEmpty else {
                throw DBXCResultParserError.invalidLocaleIdentifier(localeString)
            }
            let createdLocale = Locale(identifier: localeString)
            // Validate that the locale identifier is valid
            guard Locale.availableIdentifiers.contains(localeString) else {
                throw DBXCResultParserError.invalidLocaleIdentifier(localeString)
            }
            localeValue = createdLocale
        } else {
            localeValue = Locale.current
        }

        let formatter = DBXCTextFormatter()

        let result = formatter.format(
            report,
            include: include,
            format: format,
            locale: localeValue
        )

        print(result)
    }
}

enum DBXCResultParserError: Error {
    case invalidLocaleIdentifier(String)
}

extension DBXCTextFormatter.Format: ExpressibleByArgument {
    public init?(argument: String) {
        self.init(rawValue: argument)
    }
}
