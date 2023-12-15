import Foundation

public enum Filter: Equatable {
    case skipped
    case failed
    case mixed
    case succeeded
    case slow(duration: Duration)
}

extension Array where Element == Filter {
    var slowTestsDuration: Duration? {
        var duration: Duration?
        
        forEach { filter in
            switch filter {
            case .slow(let value):
                duration = value
            default:
                return
            }
        }
        
        return duration
    }
}
