//
//  FormatterProtocol.swift
//  
//
//  Created by Aleksey Berezka on 15.12.2023.
//

import Foundation

public protocol FormatterProtocol {
    func format(
        _ report: ReportModel,
        filters: [Filter]
    ) -> String
}
