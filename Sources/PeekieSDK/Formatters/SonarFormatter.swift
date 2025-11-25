import Foundation
import XMLCoder

public class SonarFormatter {
    public init() {}

    public func format(
        report: Report,
        testsPath: URL
    ) throws -> String {
        let fsIndex = try FSIndex(path: testsPath)

        // Group files by actual file path (multiple test suites can be in one file)
        var filesByPath: [String: [TestExecutions.File.TestCase]] = [:]

        for file in report.modules.flatMap({ $0.files }).sorted(by: { $0.name < $1.name }) {
            // Skip files that don't have any tests (coverage-only files)
            guard !file.repeatableTests.isEmpty else {
                continue
            }

            // Skip files that are not found in the index (e.g., DTO test files that don't exist)
            // Remove .swift extension for lookup since fsIndex uses class names without extension
            let lookupName =
                file.name.hasSuffix(".swift")
                ? String(file.name.dropLast(6))
                : file.name
            guard let path = fsIndex.classes[lookupName] else {
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
    init(_ test: Report.Module.File.RepeatableTest.Test) {
        self.init(
            name: test.name,
            duration: Int(test.duration.converted(to: .milliseconds).value),
            skipped: test.status == .skipped ? test.message.map { .init(message: $0) } : nil,
            failure: test.status == .failure ? test.message.map { .init(message: $0) } : nil
        )
    }
}

extension TestExecutions.File {
    fileprivate static func testCases(from file: Report.Module.File) throws -> [TestExecutions.File
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
