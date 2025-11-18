//
//  CoverageDTO+TestHelpers.swift
//
//
//  Created by Aleksey Berezka on 19.12.2023.
//

import Foundation

@testable import DBXCResultParser

extension CoverageDTO {
    public static func testMake(
        buildProductPath: String = "",
        coveredLines: Int = 0,
        executableLines: Int = 0,
        lineCoverage: Double = 0,
        name: String = ""
    ) -> CoverageDTO {
        self.init(
            buildProductPath: buildProductPath,
            coveredLines: coveredLines,
            executableLines: executableLines,
            lineCoverage: lineCoverage,
            name: name
        )
    }
}
