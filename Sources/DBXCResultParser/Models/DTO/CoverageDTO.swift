// Created by Yaroslav Bredikhin on 05.09.2022

import Foundation

struct CoverageDTO: Decodable {
    var buildProductPath: String
    var coveredLines: Int
    var executableLines: Int
    var lineCoverage: Double
    var name: String
}
