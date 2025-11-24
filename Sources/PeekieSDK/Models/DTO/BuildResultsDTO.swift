import Foundation

struct BuildResultsDTO: Decodable {
    let warnings: [Warning]?

    struct Warning: Decodable {
        let issueType: String?
        let message: String?
        let sourceURL: String?
    }
}

extension BuildResultsDTO.Warning {
    var fileName: String? {
        guard let sourceURL else { return nil }
        let url = URL(string: sourceURL) ?? URL(fileURLWithPath: sourceURL)
        let fragmentTrimmed = URL(
            string: url.absoluteString.components(separatedBy: "#").first ?? url.absoluteString)
        return (fragmentTrimmed ?? url).lastPathComponent
    }
}
