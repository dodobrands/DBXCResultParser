import Foundation

struct BuildResultsDTO: Decodable {
    let warnings: [Issue]

    struct Issue: Decodable {
        let issueType: String
        let message: String
        let sourceURL: String?
        let className: String?
    }
}
