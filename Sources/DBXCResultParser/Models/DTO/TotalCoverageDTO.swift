import Foundation

struct TotalCoverageDTO: Decodable {
    let lineCoverage: Double
    let targets: [CoverageDTO]
}
