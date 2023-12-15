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
        testResults: [ReportModel.Module.File.RepeatableTest.Test.Status]
    ) -> String
}
