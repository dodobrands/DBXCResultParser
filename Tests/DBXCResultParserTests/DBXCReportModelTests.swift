import Foundation
import Testing

// XCODE_VERSION=$(xcodebuild -version | head -1 | awk '{print $2}') && xcodebuild test -scheme DBXCResultParser-Package -destination 'platform=macOS' -enableCodeCoverage YES -retry-tests-on-failure -test-iterations 3 -collect-test-diagnostics never -enablePerformanceTestsDiagnostics NO -resultBundlePath "Tests/DBXCResultParserTests/Resources/DBXCResultParser-${XCODE_VERSION}.xcresult"
//
// Flow:
// 1) uncomment the tests below
// 2) run tests via command - a new file will be created for the new Xcode version
// 3) run tests via Xcode - it will show errors because the new file is now included in tests
// 4) update existing tests to include data for new xcresult files so tests become green
//
//
//import XCTest
//class FakeXCTests: XCTestCase {
//    func test_success() {
//        XCTAssertTrue(true)
//    }
//
//    func test_failure() {
//        XCTFail("Failure message")
//    }
//
//    func test_skip() throws {
//        throw XCTSkip("Skip message")
//    }
//
//    func test_expectedFailure() {
//        XCTExpectFailure("Failure is expected")
//        XCTAssertEqual(1, 2)
//    }
//
//    static nonisolated(unsafe) var shouldFail = true
//    func test_flacky() {
//        if Self.shouldFail {
//            XCTFail("Flacky failure message")
//        }
//
//        Self.shouldFail = false
//    }
//}

@Suite
struct FakeSUITests {
    @Test
    func success() {
        #expect(true)
    }

    @Test
    func failure() {
        Issue.record("Failure message")
    }

    @Test(.disabled("Skip message"))
    func test_skip() {
        #expect(true)
    }

    @Test
    func test_expectedFailure() {
        withKnownIssue {
            #expect(Bool(false), "Failure is expected")
        }
    }

    static nonisolated(unsafe) var shouldFail = true
    @Test
    func test_flacky() {
        if Self.shouldFail {
            Issue.record("Flacky failure message")
        }
        Self.shouldFail = false
    }

    // Parameterized tests with arguments
    @Test(arguments: [true, false])
    func test_withBooleanArgument(value: Bool) {
        #expect(value == true || value == false)
    }

    @Test(arguments: [1, 2, 3, 4, 5])
    func test_withIntegerArgument(number: Int) {
        #expect(number > 0)
        #expect(number <= 5)
    }

    @Test(arguments: ["apple", "banana", "cherry"])
    func test_withStringArgument(fruit: String) {
        #expect(!fruit.isEmpty)
    }

    @Test(arguments: [(false, true), (true, false), (true, true)])
    func test_withTupleArgument(pair: (Bool, Bool)) {
        let (first, second) = pair
        #expect(first == true || second == true)
    }

    @Test(arguments: [
        TestStatus.success, TestStatus.failure, TestStatus.skipped, TestStatus.expectedFailure,
    ])
    func test_withEnumArgument(status: TestStatus) {
        #expect(status != .unknown)
    }

    enum TestStatus: String {
        case success
        case failure
        case skipped
        case expectedFailure
        case unknown
    }
}
