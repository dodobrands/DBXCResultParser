import Foundation

public class Logger {
    private static let lock = NSLock()
    nonisolated(unsafe) private static var _verbose = false

    public static var verbose: Bool {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _verbose
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _verbose = newValue
        }
    }

    public static func logDebug(_ message: String) {
        guard verbose else { return }
        print(message)
    }

    public static func logInfo(_ message: String) {
        print(message)
    }

    public static func logWarning(_ message: String) {
        // Use ANSI escape codes for colored output in terminals that support it
        // Yellow color for warnings: \u{001B}[33m
        // Reset colors: \u{001B}[0m
        print("\u{001B}[33mWarning:\u{001B}[0m \(message)")
    }
}
