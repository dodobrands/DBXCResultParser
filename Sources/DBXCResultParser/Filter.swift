import Foundation

public enum TestResult: Equatable, CaseIterable {
    case succeeded
    case failed
    case skipped
    case mixed
}
