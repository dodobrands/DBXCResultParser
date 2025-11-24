import Foundation

public func snapshotName(from fileName: String) -> String {
    fileName.replacingOccurrences(of: ".xcresult", with: "")
}
