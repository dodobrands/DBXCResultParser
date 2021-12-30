//
//  JSONFileParser.swift
//  
//
//  Created by Алексей Берёзка on 30.12.2021.
//

import Foundation

class JSONFileParser: FileParser {
    func parse<ReportType: Decodable>() throws -> ReportType {
        let report = try JSONDecoder()
            .decode(ReportType.self, from: data())
        return report
    }
}
