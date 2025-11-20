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
        var filesByPath: [String: [testExecutions.file.testCase]] = [:]

        for file in report.modules.flatMap({ $0.files }).sorted(by: { $0.name < $1.name }) {
            let path =
                try fsIndex.classes[file.name] ?! testExecutions.file.Error.missingFile(file.name)

            // Extract test cases from this file
            let testCases = try testExecutions.file.testCases(from: file)

            // Merge test cases by file path
            if filesByPath[path] != nil {
                filesByPath[path]?.append(contentsOf: testCases)
            } else {
                filesByPath[path] = testCases
            }
        }

        // Create file entries from grouped test cases
        let sonarFiles = filesByPath.map { path, testCases in
            testExecutions.file(path: path, testCase: testCases)
        }.sorted { $0.path < $1.path }
        let dto = testExecutions(file: sonarFiles)

        let encoder = XMLEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(dto)
        return String(decoding: data, as: UTF8.self)
    }
}

private struct testExecutions: Encodable, DynamicNodeEncoding {
    let version = 1
    let file: [file]

    static func nodeEncoding(for key: CodingKey) -> XMLEncoder.NodeEncoding {
        switch key {
        case Self.CodingKeys.version:
            return .attribute
        default:
            return .element
        }
    }

    struct file: Encodable, DynamicNodeEncoding {
        let path: String
        let testCase: [testCase]

        static func nodeEncoding(for key: CodingKey) -> XMLEncoder.NodeEncoding {
            switch key {
            case Self.CodingKeys.path:
                return .attribute
            default:
                return .element
            }
        }

        struct testCase: Encodable, DynamicNodeEncoding {
            let name: String
            let duration: Int
            let skipped: skipped?
            let failure: failure?

            static func nodeEncoding(for key: CodingKey) -> XMLEncoder.NodeEncoding {
                switch key {
                case Self.CodingKeys.name,
                    Self.CodingKeys.duration:
                    return .attribute
                default:
                    return .element
                }
            }

            struct skipped: Encodable, DynamicNodeEncoding {
                let message: String

                static func nodeEncoding(for key: CodingKey) -> XMLEncoder.NodeEncoding {
                    switch key {
                    case Self.CodingKeys.message:
                        return .attribute
                    default:
                        return .element
                    }
                }
            }

            struct failure: Encodable, DynamicNodeEncoding {
                let message: String

                static func nodeEncoding(for key: CodingKey) -> XMLEncoder.NodeEncoding {
                    switch key {
                    case Self.CodingKeys.message:
                        return .attribute
                    default:
                        return .element
                    }
                }
            }
        }
    }
}

extension testExecutions.file.testCase {
    init(_ test: Report.Module.File.RepeatableTest) {
        self.init(
            name: test.name,
            duration: Int(test.totalDuration.converted(to: .milliseconds).value),
            skipped: test.combinedStatus == .skipped
                ? .init(message: test.message ?? "Test message missing") : nil,
            failure: test.combinedStatus == .failure
                ? .init(message: test.message ?? "Test message missing") : nil
        )
    }

    init(_ test: Report.Module.File.RepeatableTest.Test, repeatableTestName: String) {
        // For parameterized tests, include the message (which contains arguments) in the name
        let name: String
        if let message = test.message {
            name = "\(repeatableTestName) (\(message))"
        } else {
            name = repeatableTestName
        }

        self.init(
            name: name,
            duration: Int(test.duration.converted(to: .milliseconds).value),
            skipped: test.status == .skipped
                ? .init(message: test.message ?? "Test message missing") : nil,
            failure: test.status == .failure
                ? .init(message: test.message ?? "Test message missing") : nil
        )
    }
}

extension testExecutions.file {
    fileprivate static func testCases(from file: Report.Module.File) throws -> [testExecutions.file
        .testCase]
    {
        var testCases: [testExecutions.file.testCase] = []

        for repeatableTest in file.repeatableTests.sorted(by: { $0.name < $1.name }) {
            // Check if tests have different messages, which indicates they're parameterized
            let hasDifferentMessages =
                repeatableTest.tests.count > 1
                && Set(repeatableTest.tests.compactMap { $0.message }).count
                    == repeatableTest.tests.count

            if hasDifferentMessages {
                // Output each test separately (parameterized case)
                for test in repeatableTest.tests {
                    testCases.append(
                        testExecutions.file.testCase.init(
                            test, repeatableTestName: repeatableTest.name)
                    )
                }
            } else {
                // Single test or multiple tests with same message (repetitions/mixed), use original format
                testCases.append(testExecutions.file.testCase.init(repeatableTest))
            }
        }

        return testCases
    }

    enum Error: Swift.Error {
        case missingFile(String)
    }
}

extension Sequence {
    func concurrentMap<T: Sendable>(_ transform: @escaping @Sendable (Self.Element) throws -> T)
        rethrows -> [T]
    {
        nonisolated(unsafe) let elements = Array(self)
        nonisolated(unsafe) var results = [T?](repeating: nil, count: elements.count)
        let lock = NSLock()

        DispatchQueue.concurrentPerform(iterations: elements.count) { index in
            let transformed = try? transform(elements[index])
            lock.lock()
            results[index] = transformed
            lock.unlock()
        }

        return results.compactMap { $0 }
    }
}
