import Foundation

public struct FSIndex {
    public let classes: [String: String]

    public init(path: URL) throws {
        self.classes = try Self.classes(in: path)
    }
}

extension FSIndex {
    private static func classes(in path: URL) throws -> [String: String] {
        let fileManager = FileManager.default

        var classDictionary: [String: String] = [:]

        // Create a DirectoryEnumerator to recursively search for .swift files
        let enumerator = fileManager.enumerator(
            at: URL(fileURLWithPath: path.relativePath),
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) { (url, error) -> Bool in
            let message =
                "Warning: Directory enumeration error at \(url)\nWarning: \(error.localizedDescription)\n"
            FileHandle.standardError.write(Data(message.utf8))
            return true
        }

        // Regular expression to find class and struct names
        let regex = try NSRegularExpression(
            pattern: "(?:class|struct)\\s+([A-Za-z_][A-Za-z_0-9]*)", options: [])

        // Iterate over each file found by the enumerator
        while let element = enumerator?.nextObject() as? URL {
            let isFile =
                try element.resourceValues(forKeys: [URLResourceKey.isRegularFileKey]).isRegularFile
                ?? false
            guard isFile,
                element.pathExtension == "swift"
            else {
                continue
            }

            // Skip if file doesn't exist (may have been deleted or not created yet)
            guard FileManager.default.fileExists(atPath: element.path) else {
                continue
            }

            let fileContent = try String(contentsOf: element, encoding: .utf8)

            // Search for class definitions
            let nsRange = NSRange(fileContent.startIndex..<fileContent.endIndex, in: fileContent)
            let matches = regex.matches(in: fileContent, options: [], range: nsRange)

            // Extract class names from the matches and store them in the dictionary
            for match in matches {
                if let range = Range(match.range(at: 1), in: fileContent) {
                    let className = String(fileContent[range])
                    let relativePath: String =
                        try element.relativePath(from: path)
                        ?! Error.cantGetRelativePath(filePath: element, basePath: path)
                    classDictionary[className] = relativePath
                }
            }
        }

        return classDictionary
    }

    public enum Error: Swift.Error {
        case cantGetRelativePath(filePath: URL, basePath: URL)
    }
}
