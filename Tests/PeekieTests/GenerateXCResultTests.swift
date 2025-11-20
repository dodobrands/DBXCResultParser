import Foundation
import Testing

// XCODE_VERSION=$(xcodebuild -version | head -1 | awk '{print $2}') && xcodebuild test -scheme DBXCResultParser-Package -destination 'platform=macOS' -enableCodeCoverage YES -retry-tests-on-failure -test-iterations 3 -collect-test-diagnostics never -enablePerformanceTestsDiagnostics NO -resultBundlePath "Tests/PeekieTests/Resources/DBXCResultParser-${XCODE_VERSION}.xcresult"
//
// Flow:
// 1) uncomment the tests below
// 2) run tests via command - a new file will be created for the new Xcode version
// 3) delete all snapshots
// 4) comment the tests below
// 5) run tests via Xcode - it will show errors because:
//      - the new xcresult file is now included in tests
//      - new snapshots are generated
// 6) update existing tests to include data for new xcresult files so tests become green
// 7) validate new snapshots are ok
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
//
//@Suite
//struct FakeSUITests {
//    @Test
//    func success() {
//        #expect(true)
//    }
//
//    @Test
//    func failure() {
//        Issue.record("Failure message")
//    }
//
//    @Test(.disabled("Disabled reason"))
//    func disabled() {
//        #expect(true)
//    }
//
//    @Test
//    func expectedFailure() {
//        withKnownIssue {
//            #expect(Bool(false), "Failure is expected")
//        }
//    }
//
//    static nonisolated(unsafe) var shouldFail = true
//    @Test
//    func flacky() {
//        if Self.shouldFail {
//            Issue.record("Flacky failure message")
//        }
//        Self.shouldFail = false
//    }
//
//    @Test(arguments: [true, false])
//    func flackyParameterized(value: Bool) {
//        #expect(value == true)
//    }
//
//    @Test
//    func somethingWithWarning() {
//#warning("Some warning to appear in xcresult")
//        #expect(true)
//    }
//}
