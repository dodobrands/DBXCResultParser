import Foundation
import Testing

@testable import peekiesdk

@Suite
struct ShellTests {
    @Test
    func test() async throws {
        let result = try await Shell.execute("which", arguments: ["swift"])
        #expect(result == "/usr/bin/swift")
    }
}
