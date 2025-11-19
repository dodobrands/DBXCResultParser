//
//  TotalCoverageDTO.swift
//
//
//  Created on 19.11.2025.
//

import Foundation

struct TotalCoverageDTO: Decodable {
    let coveredLines: Int
    let executableLines: Int
    let lineCoverage: Double
    let targets: [CoverageDTO]
}
