import Foundation

extension TestResultsDTO {
    init(from xcresultPath: URL) async throws {
        let output = try await Shell.execute(
            "xcrun",
            arguments: [
                "xcresulttool", "get", "test-results", "tests",
                "--path", xcresultPath.path,
                "--compact",
            ]
        )
        guard let data = output.data(using: .utf8) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: [],
                    debugDescription: "Failed to convert output to Data"
                )
            )
        }
        self = try JSONDecoder().decode(TestResultsDTO.self, from: data)
    }
}

extension Array where Element == CoverageDTO {
    init(from xcresultPath: URL) async throws {
        let output = try await Shell.execute(
            "xcrun",
            arguments: [
                "xccov", "view", "--report", "--only-targets", "--json",
                xcresultPath.path,
            ]
        )
        guard let data = output.data(using: .utf8) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: [],
                    debugDescription: "Failed to convert output to Data"
                )
            )
        }
        self = try JSONDecoder().decode(Array<CoverageDTO>.self, from: data)
    }
}

extension CoverageReportDTO {
    init(from xcresultPath: URL) async throws {
        let output = try await Shell.execute(
            "xcrun",
            arguments: [
                "xccov", "view", "--report", "--json",
                xcresultPath.path,
            ]
        )
        guard let data = output.data(using: .utf8) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: [],
                    debugDescription: "Failed to convert output to Data"
                )
            )
        }
        self = try JSONDecoder().decode(CoverageReportDTO.self, from: data)
    }
}

extension TotalCoverageDTO {
    init(from xcresultPath: URL) async throws {
        let output = try await Shell.execute(
            "xcrun",
            arguments: [
                "xccov", "view", "--report", "--json",
                xcresultPath.path,
            ]
        )
        guard let data = output.data(using: .utf8) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: [],
                    debugDescription: "Failed to convert output to Data"
                )
            )
        }
        self = try JSONDecoder().decode(TotalCoverageDTO.self, from: data)
    }
}

extension BuildResultsDTO {
    init(from xcresultPath: URL) async throws {
        let output = try await Shell.execute(
            "xcrun",
            arguments: [
                "xcresulttool", "get", "build-results",
                "--path", xcresultPath.path,
                "--format", "json",
            ]
        )
        guard let data = output.data(using: .utf8) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: [],
                    debugDescription: "Failed to convert output to Data"
                )
            )
        }
        self = try JSONDecoder().decode(BuildResultsDTO.self, from: data)
    }
}
