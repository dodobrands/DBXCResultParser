//
//  main.swift
//  TestReportParser
//
//  Created by Станислав Карпенко on 23.04.2021.
//

import Foundation
import TestParser

let path = CommandLine.arguments[1]
let filter = ReportParser.Filter(rawValue: CommandLine.arguments[2])!
let format = ReportParser.Format(rawValue: CommandLine.arguments[3])!
let url = URL(fileURLWithPath: path)
let parser = try ReportParser(xcresultPath: url)
let result = try parser.parse(filter: filter, format: format)

print("\(result)")
