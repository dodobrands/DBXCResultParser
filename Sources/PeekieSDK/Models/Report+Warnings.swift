import Foundation

extension Report {
    // MARK: - Warnings Processing

    /// Parses warnings from BuildResultsDTO and returns a map of file names to their issues
    static func parseWarnings(
        from buildResultsDTO: BuildResultsDTO
    ) -> [String: [Module.File.Issue]] {
        let warnings = buildResultsDTO.warnings
        guard !warnings.isEmpty else { return [:] }

        var map: [String: [Module.File.Issue]] = [:]
        var seenMessages: [String: Set<String>] = [:]

        for warning in warnings {
            // Try to create IssueType from rawValue, skip if not supported
            guard
                let issueType = Module.File.Issue.IssueType(rawValue: warning.issueType)
            else { continue }

            let message = warning.message.trimmingCharacters(in: .whitespacesAndNewlines)
            guard
                !message.isEmpty,
                let fileName = warning.fileName
            else { continue }

            // Normalize message to remove duplicates and clean up
            let normalized = normalizeWarningMessage(message)
            guard !normalized.isEmpty else { continue }

            // Check for duplicates using normalized message
            var seen = seenMessages[fileName, default: []]
            if seen.contains(normalized) { continue }
            seen.insert(normalized)
            seenMessages[fileName] = seen

            // Store normalized message in the warning
            let parsedWarning = Module.File.Issue(
                type: issueType,
                message: normalized
            )

            map[fileName, default: []].append(parsedWarning)
        }

        return map
    }

    /// Normalizes a warning message by removing duplicate patterns and cleaning up formatting
    static func normalizeWarningMessage(_ message: String) -> String {
        // 1) Remove duplicate #warning patterns: message followed by #warning("message")
        let duplicateWarningRemoved: String = {
            // Pattern: message\n#warning("message")
            // Using named capture group to match the message and its duplicate
            let pattern = "(?m)^(.+?)\\r?\\n#warning\\(\"\\1\"\\)"
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let range = NSRange(location: 0, length: (message as NSString).length)
                let result = regex.stringByReplacingMatches(
                    in: message,
                    options: [],
                    range: range,
                    withTemplate: "$1"
                )
                return result
            }
            return message
        }()

        // 2) Drop caret pointer lines and remaining #warning lines
        let caretAndWarningFiltered: String = {
            let lines = duplicateWarningRemoved.split(whereSeparator: \.isNewline)
            let filtered = lines.filter { line in
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.hasPrefix("^") { return false }
                if trimmed.hasPrefix("#warning(") { return false }
                return true
            }
            return filtered.joined(separator: "\n")
        }()

        // 3) Collapse whitespace
        let regex = try? NSRegularExpression(pattern: "\\s+", options: [])
        let range = NSRange(
            location: 0, length: (caretAndWarningFiltered as NSString).length)
        let collapsed =
            regex?.stringByReplacingMatches(
                in: caretAndWarningFiltered,
                options: [],
                range: range,
                withTemplate: " "
            ) ?? caretAndWarningFiltered

        return collapsed.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Finds warnings for a given file name by checking various candidate names
    static func findWarnings(
        for fileName: String,
        in warningsByFileName: [String: [Module.File.Issue]]
    ) -> [Module.File.Issue] {
        var candidates: [String] = [fileName]
        if !fileName.hasSuffix(".swift") {
            candidates.append(fileName + ".swift")
        }

        let baseName = fileName.replacingOccurrences(of: "Tests", with: "")
        if baseName != fileName {
            candidates.append(baseName)
            if !baseName.hasSuffix(".swift") {
                candidates.append(baseName + ".swift")
            }
        }

        for candidate in candidates {
            if let warnings = warningsByFileName[candidate] {
                return warnings
            }
        }

        return []
    }

    /// Merges two arrays of warnings, removing duplicates based on message content
    static func mergeWarnings(
        _ existing: [Module.File.Issue],
        _ new: [Module.File.Issue]
    ) -> [Module.File.Issue] {
        guard !new.isEmpty else { return existing }
        var combined = existing
        // Use normalized messages for comparison since warnings are already normalized
        let existingMessages = Set(combined.map { $0.message })
        for warning in new where !existingMessages.contains(warning.message) {
            combined.append(warning)
        }
        return combined
    }
}
