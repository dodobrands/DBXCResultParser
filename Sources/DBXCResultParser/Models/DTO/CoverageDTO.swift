import Foundation

struct CoverageDTO: Decodable {
    var coveredLines: Int
    var executableLines: Int
    var lineCoverage: Double
    var name: String
}
