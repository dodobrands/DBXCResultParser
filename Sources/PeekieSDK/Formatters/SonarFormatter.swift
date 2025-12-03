import Foundation
import Logging
import XMLCoder

/// Formatter that generates SonarQube Generic Test Execution XML format
///
/// This formatter converts test results into XML format compatible with SonarQube's
/// Generic Test Data import feature, enabling test result visualization in SonarQube dashboards.
///
/// - Note: Requires a testsPath directory to map test suite names to actual file paths,
///   as xcresult files only contain suite URLs without file paths.
public class SonarFormatter {
    private let logger = Logger(label: "com.peekie.formatter.sonar")

    /// Creates a new SonarQube formatter instance
    public init() {}

    /// Formats a report into SonarQube Generic Test Execution XML
    /// - Parameters:
    ///   - report: The parsed test report to format
    ///   - testsPath: Directory containing test source files for file path resolution
    /// - Returns: XML string in SonarQube Generic Test Execution format
    /// - Throws: Error if file path resolution fails or XML encoding fails
    public func format(
        report: Report,
        testsPath: URL
    ) throws -> String {
        let fsIndex = try FSIndex(path: testsPath)

        logger.debug(
            "FSIndex created",
            metadata: [
                "testsPath": "\(testsPath.path)",
                "classesCount": "\(fsIndex.classes.count)",
            ]
        )

        // Group files by actual file path (multiple test suites can be in one file)
        var filesByPath: [String: [TestExecutions.File.TestCase]] = [:]
        // Track paths by nodeIdentifierURL (full node identifier)
        var pathsByNode: [String: String] = [:]

        for file in report.modules.flatMap({ $0.suites }).sorted(by: { $0.name < $1.name }) {
            // Skip files that don't have any tests (coverage-only files)
            guard !file.repeatableTests.isEmpty else {
                logger.debug(
                    "Skipping Suite: no tests",
                    metadata: [
                        "suiteName": "\(file.name)",
                        "nodeIdentifierURL": "\(file.nodeIdentifierURL)",
                    ]
                )
                continue
            }

            // Extract class name from nodeIdentifierURL (lastPathComponent)
            guard let url = URL(string: file.nodeIdentifierURL) else {
                logger.debug(
                    "Skipping Suite: cannot parse nodeIdentifierURL as URL",
                    metadata: [
                        "suiteName": "\(file.name)",
                        "nodeIdentifierURL": "\(file.nodeIdentifierURL)",
                    ]
                )
                continue
            }
            let className = url.lastPathComponent

            logger.debug(
                "Looking up Suite in FSIndex",
                metadata: [
                    "suiteName": "\(file.name)",
                    "nodeIdentifierURL": "\(file.nodeIdentifierURL)",
                    "className": "\(className)",
                ]
            )

            // Check if we already have path for this nodeIdentifierURL
            let path: String
            if let cachedPath = pathsByNode[file.nodeIdentifierURL] {
                path = cachedPath
                logger.debug(
                    "Using cached path for nodeIdentifierURL",
                    metadata: [
                        "suiteName": "\(file.name)",
                        "nodeIdentifierURL": "\(file.nodeIdentifierURL)",
                        "path": "\(path)",
                    ]
                )
            } else if let foundPath = fsIndex.classes[className] {
                path = foundPath
                pathsByNode[file.nodeIdentifierURL] = path
                logger.debug(
                    "Found Suite in FSIndex",
                    metadata: [
                        "suiteName": "\(file.name)",
                        "nodeIdentifierURL": "\(file.nodeIdentifierURL)",
                        "className": "\(className)",
                        "path": "\(path)",
                    ]
                )
            } else {
                logger.debug(
                    "Skipping Suite: not found in FSIndex",
                    metadata: [
                        "suiteName": "\(file.name)",
                        "nodeIdentifierURL": "\(file.nodeIdentifierURL)",
                        "className": "\(className)",
                        "availableClasses":
                            "\(Array(fsIndex.classes.keys.sorted().prefix(10)).joined(separator: ", "))",
                    ]
                )
                continue
            }

            // Extract test cases from this file
            let testCases = try TestExecutions.File.testCases(from: file)

            // Merge test cases by file path
            if filesByPath[path] != nil {
                filesByPath[path]?.append(contentsOf: testCases)
            } else {
                filesByPath[path] = testCases
            }
        }

        // Create file entries from grouped test cases
        let sonarFiles = filesByPath.map { path, testCases in
            TestExecutions.File(path: path, testCase: testCases)
        }.sorted { $0.path < $1.path }
        let dto = TestExecutionsRoot(testExecutions: TestExecutions(file: sonarFiles))

        let encoder = XMLEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(dto)
        return String(decoding: data, as: UTF8.self)
    }
}

private struct TestExecutionsRoot: Encodable, DynamicNodeEncoding {
    let testExecutions: TestExecutions

    enum CodingKeys: String, CodingKey {
        case testExecutions = "testExecutions"
    }

    static func nodeEncoding(for key: CodingKey) -> XMLEncoder.NodeEncoding {
        return .element
    }
}

private struct TestExecutions: Encodable, DynamicNodeEncoding {
    let version = 1
    let file: [File]

    enum CodingKeys: String, CodingKey {
        case version
        case file
    }

    static func nodeEncoding(for key: CodingKey) -> XMLEncoder.NodeEncoding {
        switch key {
        case CodingKeys.version:
            return .attribute
        default:
            return .element
        }
    }

    struct File: Encodable, DynamicNodeEncoding {
        let path: String
        let testCase: [TestCase]

        enum CodingKeys: String, CodingKey {
            case path
            case testCase
        }

        static func nodeEncoding(for key: CodingKey) -> XMLEncoder.NodeEncoding {
            switch key {
            case CodingKeys.path:
                return .attribute
            default:
                return .element
            }
        }

        struct TestCase: Encodable, DynamicNodeEncoding {
            let name: String
            let duration: Int
            let skipped: Skipped?
            let failure: Failure?

            enum CodingKeys: String, CodingKey {
                case name
                case duration
                case skipped
                case failure
            }

            static func nodeEncoding(for key: CodingKey) -> XMLEncoder.NodeEncoding {
                switch key {
                case CodingKeys.name,
                    CodingKeys.duration:
                    return .attribute
                default:
                    return .element
                }
            }

            struct Skipped: Encodable, DynamicNodeEncoding {
                let message: String

                enum CodingKeys: String, CodingKey {
                    case message
                }

                static func nodeEncoding(for key: CodingKey) -> XMLEncoder.NodeEncoding {
                    switch key {
                    case CodingKeys.message:
                        return .attribute
                    default:
                        return .element
                    }
                }
            }

            struct Failure: Encodable, DynamicNodeEncoding {
                let message: String

                enum CodingKeys: String, CodingKey {
                    case message
                }

                static func nodeEncoding(for key: CodingKey) -> XMLEncoder.NodeEncoding {
                    switch key {
                    case CodingKeys.message:
                        return .attribute
                    default:
                        return .element
                    }
                }
            }
        }
    }
}

extension TestExecutions.File.TestCase {
    init(_ test: Report.Module.Suite.RepeatableTest.Test) {
        self.init(
            name: test.name,
            duration: Int(test.duration.converted(to: .milliseconds).value),
            skipped: test.status == .skipped ? test.message.map { .init(message: $0) } : nil,
            failure: test.status == .failure ? test.message.map { .init(message: $0) } : nil
        )
    }
}

extension TestExecutions.File {
    fileprivate static func testCases(from file: Report.Module.Suite) throws -> [TestExecutions.File
        .TestCase]
    {
        var testCases: [TestExecutions.File.TestCase] = []

        for repeatableTest in file.repeatableTests.sorted(by: { $0.name < $1.name }) {
            // Use merged tests which already handle repetitions and optionally devices
            let mergedTests = repeatableTest.mergedTests(filterDevice: false)

            // Output each merged test separately
            for test in mergedTests {
                testCases.append(TestExecutions.File.TestCase.init(test))
            }
        }

        return testCases
    }
}
