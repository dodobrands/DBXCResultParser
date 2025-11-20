import Foundation
import Testing

@testable import peekiesdk

@Suite
struct DBShellTests {
    @Test
    func test() async throws {
        let result = try await DBShell.execute("which", arguments: ["swift"])
        #expect(result == "/usr/bin/swift")
    }
}
