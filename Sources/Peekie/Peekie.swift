import ArgumentParser
import Foundation
import PeekieSDK

@main
public struct Peekie: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "peekie",
        abstract: "Parse and format Xcode .xcresult files",
        subcommands: [Text.self, Sonar.self]
    )

    public init() {}
}

enum PeekieSDKError: Error {
    case invalidLocaleIdentifier(String)
}
